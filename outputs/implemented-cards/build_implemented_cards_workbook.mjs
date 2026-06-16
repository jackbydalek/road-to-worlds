import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";
import {
  ARCHETYPES,
  combatSummary,
  archetypeFor,
  sortCards,
} from "../../tools/export_card_lists.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "../..");
const cardsPath = path.join(repoRoot, "data/content/cards.json");
const outputPath = path.join(__dirname, "road_to_worlds_implemented_cards.xlsx");

function titleCase(value) {
  return String(value ?? "")
    .split("_")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function cardType(card) {
  const kind = String(card.combat?.kind ?? "");
  if (kind === "unit") return "Unit";
  if (kind === "action") return "Action";
  if (kind === "engine") return "Engine";
  return titleCase(card.role ?? "card");
}

function gameplayStats(card) {
  const combat = card.combat ?? {};
  if (combat.kind !== "unit") return "N/A";

  const pieces = [`${combat.attack ?? 0}/${combat.health ?? 1}`];
  const keywords = Array.isArray(combat.keywords) ? combat.keywords : [];
  if (keywords.length > 0) pieces.push(`keywords: ${keywords.join(", ")}`);
  if (combat.ready) pieces.push("ready immediately");
  return pieces.join("; ");
}

function countBy(items, getter) {
  const counts = new Map();
  for (const item of items) {
    const key = getter(item);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return [...counts.entries()].sort((a, b) => String(a[0]).localeCompare(String(b[0])));
}

function columnLetter(index) {
  let n = index + 1;
  let letters = "";
  while (n > 0) {
    const mod = (n - 1) % 26;
    letters = String.fromCharCode(65 + mod) + letters;
    n = Math.floor((n - mod) / 26);
  }
  return letters;
}

function a1Range(startCol, startRow, colCount, rowCount) {
  const endCol = columnLetter(startCol + colCount - 1);
  const endRow = startRow + rowCount - 1;
  return `${columnLetter(startCol)}${startRow}:${endCol}${endRow}`;
}

function applyWidth(sheet, column, px) {
  const range = sheet.getRange(`${column}:${column}`);
  try {
    range.format.columnWidthPx = px;
  } catch {
    // Older artifact-tool runtimes may ignore fixed-width setters.
  }
}

function mergeIfPossible(sheet, address) {
  try {
    sheet.getRange(address).merge();
  } catch {
    // If merge is unavailable, leave the values in the first cell.
  }
}

function styleSheet(sheet, rowCount) {
  const fullRange = sheet.getRange(`A1:I${rowCount}`);
  fullRange.format = {
    font: { name: "Aptos", size: 10, color: "#1F2937" },
    verticalAlignment: "top",
    wrapText: true,
  };

  sheet.getRange("A1:I1").format = {
    fill: "#26333F",
    font: { name: "Aptos Display", size: 16, color: "#FFFFFF", bold: true },
    borders: { preset: "outside", style: "thin", color: "#26333F" },
    verticalAlignment: "center",
  };

  sheet.getRange("A3:I3").format = {
    fill: "#D8E7E1",
    font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
    borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
  };

  if (rowCount > 3) {
    sheet.getRange(`A4:I${rowCount}`).format = {
      fill: "#FBFCFD",
      borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
      verticalAlignment: "top",
      wrapText: true,
    };
    sheet.getRange(`E4:E${rowCount}`).format.horizontalAlignment = "center";
    sheet.getRange(`G4:H${rowCount}`).format.horizontalAlignment = "center";
  }

  sheet.getRange(`A4:A${rowCount}`).format.font = {
    name: "Aptos",
    size: 10,
    color: "#111827",
    bold: true,
  };

  applyWidth(sheet, "A", 190);
  applyWidth(sheet, "B", 145);
  applyWidth(sheet, "C", 90);
  applyWidth(sheet, "D", 70);
  applyWidth(sheet, "E", 150);
  applyWidth(sheet, "F", 520);
  applyWidth(sheet, "G", 100);
  applyWidth(sheet, "H", 95);
  applyWidth(sheet, "I", 190);

  try {
    sheet.getRange(`A1:I${rowCount}`).format.autofitRows();
  } catch {
    // Row autofit is a visual nicety; the workbook remains usable without it.
  }
}

function styleSummarySheet(sheet, rowCount) {
  sheet.getRange(`A1:F${rowCount}`).format = {
    font: { name: "Aptos", size: 10, color: "#1F2937" },
    verticalAlignment: "top",
    wrapText: true,
  };
  sheet.getRange("A1:F1").format = {
    fill: "#26333F",
    font: { name: "Aptos Display", size: 16, color: "#FFFFFF", bold: true },
  };
  sheet.getRange("A4:B4").format = {
    fill: "#D8E7E1",
    font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
    borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
  };
  sheet.getRange("D4:E4").format = {
    fill: "#D8E7E1",
    font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
    borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
  };
  sheet.getRange(`A5:B${rowCount}`).format = {
    borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
  };
  sheet.getRange(`D5:E${rowCount}`).format = {
    borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
  };
  for (const [column, px] of [
    ["A", 180],
    ["B", 90],
    ["D", 180],
    ["E", 90],
    ["F", 320],
  ]) {
    applyWidth(sheet, column, px);
  }
}

async function main() {
  const raw = await fs.readFile(cardsPath, "utf8");
  const data = JSON.parse(raw);
  const implementedCards = sortCards(
    (data.cards ?? []).filter((card) => card.combat && Object.keys(card.combat).length > 0),
  );

  const workbook = Workbook.create();
  const cardSheet = workbook.worksheets.add("Implemented Cards");
  const summarySheet = workbook.worksheets.add("Summary");

  const headers = [
    "Name",
    "Archetype",
    "Card Type",
    "Cost",
    "Stats",
    "Implemented Gameplay Effect",
    "Role",
    "Rarity",
    "Card ID",
  ];

  const rows = implementedCards.map((card) => [
    card.name ?? "",
    ARCHETYPES[archetypeFor(card)] ?? titleCase(card.archetype ?? "neutral"),
    cardType(card),
    Number(card.cost ?? 0),
    gameplayStats(card),
    combatSummary(card),
    titleCase(card.role ?? ""),
    titleCase(card.rarity ?? ""),
    card.id ?? "",
  ]);

  cardSheet.getRange("A1:I1").values = [["Road to Worlds - Implemented Gameplay Cards", "", "", "", "", "", "", "", ""]];
  cardSheet.getRange("A2:I2").values = [[
    `Source: data/content/cards.json. Inclusion rule: cards loaded by gameplay with an explicit combat object. Total cards: ${implementedCards.length}.`,
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
  ]];
  cardSheet.getRange("A3:I3").values = [headers];
  cardSheet.getRange(a1Range(0, 4, headers.length, rows.length)).values = rows;
  mergeIfPossible(cardSheet, "A1:I1");
  mergeIfPossible(cardSheet, "A2:I2");
  styleSheet(cardSheet, rows.length + 3);

  const byType = countBy(implementedCards, cardType);
  const byArchetype = countBy(
    implementedCards,
    (card) => ARCHETYPES[archetypeFor(card)] ?? titleCase(card.archetype ?? "neutral"),
  );
  const summaryRows = [
    ["Road to Worlds - Card Implementation Summary", "", "", "", "", ""],
    ["Generated", "2026-06-16", "", "", "", ""],
    ["Source", "data/content/cards.json", "", "Inclusion Rule", "Explicit combat object loaded by Main.gd", ""],
    ["Card Type", "Count", "", "Archetype", "Count", ""],
  ];
  const maxRows = Math.max(byType.length, byArchetype.length);
  for (let i = 0; i < maxRows; i += 1) {
    summaryRows.push([
      byType[i]?.[0] ?? "",
      byType[i]?.[1] ?? "",
      "",
      byArchetype[i]?.[0] ?? "",
      byArchetype[i]?.[1] ?? "",
      "",
    ]);
  }
  summaryRows.push(["", "", "", "", "", ""]);
  summaryRows.push(["Total Implemented Cards", implementedCards.length, "", "", "", ""]);
  summarySheet.getRange(a1Range(0, 1, 6, summaryRows.length)).values = summaryRows;
  mergeIfPossible(summarySheet, "A1:F1");
  styleSummarySheet(summarySheet, summaryRows.length);

  const check = await workbook.inspect({
    kind: "table",
    range: `Implemented Cards!A1:I${Math.min(rows.length + 3, 16)}`,
    include: "values,formulas",
    tableMaxRows: 16,
    tableMaxCols: 9,
  });
  console.log(check.ndjson);

  const errors = await workbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
    options: { useRegex: true, maxResults: 300 },
    summary: "final formula error scan",
  });
  console.log(errors.ndjson);

  const renderCards = await workbook.render({
    sheetName: "Implemented Cards",
    range: "A1:I24",
    scale: 1,
  });
  await fs.writeFile(
    path.join(__dirname, "implemented_cards_preview.png"),
    Buffer.from(await renderCards.arrayBuffer()),
  );
  const renderSummary = await workbook.render({
    sheetName: "Summary",
    range: "A1:F12",
    scale: 1,
  });
  await fs.writeFile(
    path.join(__dirname, "summary_preview.png"),
    Buffer.from(await renderSummary.arrayBuffer()),
  );

  const output = await SpreadsheetFile.exportXlsx(workbook);
  await output.save(outputPath);
  console.log(`Wrote ${outputPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

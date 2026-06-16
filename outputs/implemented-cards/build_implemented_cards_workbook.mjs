import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";
import { combatSummary } from "../../tools/export_card_lists.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "../..");
const cardsPath = path.join(repoRoot, "data/content/cards.json");
const archetypesPath = path.join(repoRoot, "data/content/archetypes.json");
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

function archetypeName(card, archetypesById) {
  const archetypeId = String(card.archetype ?? "neutral");
  if (archetypeId === "neutral") return "Universal / Neutral";
  return archetypesById.get(archetypeId)?.name ?? titleCase(archetypeId);
}

function sortCardsForWorkbook(cards, archetypes) {
  const order = new Map(archetypes.map((archetype, index) => [String(archetype.id), index]));
  order.set("neutral", archetypes.length);
  const rarityOrder = { common: 0, uncommon: 1, rare: 2, mythic: 3 };

  return [...cards].sort((a, b) => {
    const groupA = order.get(String(a.archetype ?? "neutral")) ?? 999;
    const groupB = order.get(String(b.archetype ?? "neutral")) ?? 999;
    if (groupA !== groupB) return groupA - groupB;

    const rarityA = rarityOrder[String(a.rarity ?? "")] ?? 99;
    const rarityB = rarityOrder[String(b.rarity ?? "")] ?? 99;
    if (rarityA !== rarityB) return rarityA - rarityB;

    return Number(a.cost ?? 0) - Number(b.cost ?? 0)
      || String(a.name ?? "").localeCompare(String(b.name ?? ""));
  });
}

function buildStarterDeckMap(archetypes) {
  const starterMap = new Map();
  for (const archetype of archetypes) {
    const starterName = String(archetype.name ?? archetype.id ?? "Starter");
    for (const entry of archetype.starterDeck ?? []) {
      const cardId = String(entry.cardId ?? "");
      if (cardId === "") continue;
      if (!starterMap.has(cardId)) starterMap.set(cardId, []);
      starterMap.get(cardId).push({
        name: starterName,
        count: Number(entry.count ?? 0),
      });
    }
  }
  return starterMap;
}

function starterDeckCopies(card, starterDeckMap) {
  const entries = starterDeckMap.get(String(card.id ?? "")) ?? [];
  if (entries.length === 0) return "";
  return entries.map((entry) => `${entry.name} x${entry.count}`).join("; ");
}

function starterAdjustedSummary(card, archetypesById) {
  let summary = combatSummary(card);
  for (const [id, archetype] of archetypesById.entries()) {
    summary = summary.replaceAll(`${titleCase(id)}-restricted`, `${archetype.name}-restricted`);
  }
  return summary;
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
  const fullRange = sheet.getRange(`A1:K${rowCount}`);
  fullRange.format = {
    font: { name: "Aptos", size: 10, color: "#1F2937" },
    verticalAlignment: "top",
    wrapText: true,
  };

  sheet.getRange("A1:K1").format = {
    fill: "#26333F",
    font: { name: "Aptos Display", size: 16, color: "#FFFFFF", bold: true },
    borders: { preset: "outside", style: "thin", color: "#26333F" },
    verticalAlignment: "center",
  };

  sheet.getRange("A3:K3").format = {
    fill: "#D8E7E1",
    font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
    borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
  };

  if (rowCount > 3) {
    sheet.getRange(`A4:K${rowCount}`).format = {
      fill: "#FBFCFD",
      borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
      verticalAlignment: "top",
      wrapText: true,
    };
    sheet.getRange(`D4:D${rowCount}`).format.horizontalAlignment = "center";
    sheet.getRange(`F4:G${rowCount}`).format.horizontalAlignment = "center";
    sheet.getRange(`I4:J${rowCount}`).format.horizontalAlignment = "center";
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
  applyWidth(sheet, "D", 90);
  applyWidth(sheet, "E", 260);
  applyWidth(sheet, "F", 70);
  applyWidth(sheet, "G", 150);
  applyWidth(sheet, "H", 520);
  applyWidth(sheet, "I", 100);
  applyWidth(sheet, "J", 95);
  applyWidth(sheet, "K", 190);

  try {
    sheet.getRange(`A1:K${rowCount}`).format.autofitRows();
  } catch {
    // Row autofit is a visual nicety; the workbook remains usable without it.
  }
}

function styleSummarySheet(sheet, rowCount, starterHeaderRow) {
  sheet.getRange(`A1:G${rowCount}`).format = {
    font: { name: "Aptos", size: 10, color: "#1F2937" },
    verticalAlignment: "top",
    wrapText: true,
  };
  sheet.getRange("A1:G1").format = {
    fill: "#26333F",
    font: { name: "Aptos Display", size: 16, color: "#FFFFFF", bold: true },
  };
  for (const headerRange of ["A4:B4", "D4:E4", `A${starterHeaderRow}:C${starterHeaderRow}`]) {
    sheet.getRange(headerRange).format = {
      fill: "#D8E7E1",
      font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
      borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
    };
  }
  sheet.getRange(`A5:B${rowCount}`).format = {
    borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
  };
  sheet.getRange(`D5:E${rowCount}`).format = {
    borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
  };
  sheet.getRange(`A${starterHeaderRow + 1}:C${rowCount}`).format = {
    fill: "#D8E7E1",
    borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
  };
  for (const [column, px] of [
    ["A", 180],
    ["B", 90],
    ["C", 95],
    ["D", 180],
    ["E", 90],
    ["F", 320],
    ["G", 90],
  ]) {
    applyWidth(sheet, column, px);
  }
}

async function main() {
  const raw = await fs.readFile(cardsPath, "utf8");
  const archetypeRaw = await fs.readFile(archetypesPath, "utf8");
  const data = JSON.parse(raw);
  const archetypeData = JSON.parse(archetypeRaw);
  const archetypes = archetypeData.archetypes ?? [];
  const archetypesById = new Map(archetypes.map((archetype) => [String(archetype.id), archetype]));
  const starterDeckMap = buildStarterDeckMap(archetypes);
  const implementedCards = sortCardsForWorkbook(
    (data.cards ?? []).filter((card) => card.combat && Object.keys(card.combat).length > 0),
    archetypes,
  );

  const workbook = Workbook.create();
  const cardSheet = workbook.worksheets.add("Implemented Cards");
  const summarySheet = workbook.worksheets.add("Summary");

  const headers = [
    "Name",
    "Archetype",
    "Card Type",
    "Starter Deck?",
    "Starter Deck Copies",
    "Cost",
    "Stats",
    "Implemented Gameplay Effect",
    "Role",
    "Rarity",
    "Card ID",
  ];

  const rows = implementedCards.map((card) => [
    card.name ?? "",
    archetypeName(card, archetypesById),
    cardType(card),
    starterDeckMap.has(String(card.id ?? "")) ? "Yes" : "No",
    starterDeckCopies(card, starterDeckMap),
    Number(card.cost ?? 0),
    gameplayStats(card),
    starterAdjustedSummary(card, archetypesById),
    titleCase(card.role ?? ""),
    titleCase(card.rarity ?? ""),
    card.id ?? "",
  ]);

  cardSheet.getRange("A1:K1").values = [["Road to Worlds - Implemented Gameplay Cards", "", "", "", "", "", "", "", "", "", ""]];
  cardSheet.getRange("A2:K2").values = [[
    `Source: data/content/cards.json. Inclusion rule: cards loaded by gameplay with an explicit combat object. Total cards: ${implementedCards.length}.`,
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
  ]];
  cardSheet.getRange("A3:K3").values = [headers];
  cardSheet.getRange(a1Range(0, 4, headers.length, rows.length)).values = rows;
  mergeIfPossible(cardSheet, "A1:K1");
  mergeIfPossible(cardSheet, "A2:K2");
  styleSheet(cardSheet, rows.length + 3);

  const byType = countBy(implementedCards, cardType);
  const byArchetype = countBy(
    implementedCards,
    (card) => archetypeName(card, archetypesById),
  );
  const starterDeckRows = archetypes.map((archetype) => {
    const entries = archetype.starterDeck ?? [];
    return [
      String(archetype.name ?? archetype.id ?? ""),
      new Set(entries.map((entry) => String(entry.cardId ?? ""))).size,
      entries.reduce((sum, entry) => sum + Number(entry.count ?? 0), 0),
    ];
  });
  const starterUniqueCount = new Set([...starterDeckMap.keys()]).size;
  const summaryRows = [
    ["Road to Worlds - Card Implementation Summary", "", "", "", "", "", ""],
    ["Generated", "2026-06-16", "", "", "", "", ""],
    ["Source", "data/content/cards.json", "", "Inclusion Rule", "Explicit combat object loaded by Main.gd", "", ""],
    ["Card Type", "Count", "", "Archetype", "Count", "", ""],
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
      "",
    ]);
  }
  summaryRows.push(["", "", "", "", "", "", ""]);
  summaryRows.push(["Total Implemented Cards", implementedCards.length, "", "Unique Starter Cards", starterUniqueCount, "", ""]);
  summaryRows.push(["", "", "", "", "", "", ""]);
  const starterHeaderRow = summaryRows.length + 1;
  summaryRows.push(["Starter Deck", "Unique Cards", "Total Copies", "", "", "", ""]);
  for (const row of starterDeckRows) {
    summaryRows.push([row[0], row[1], row[2], "", "", "", ""]);
  }
  summarySheet.getRange(a1Range(0, 1, 7, summaryRows.length)).values = summaryRows;
  mergeIfPossible(summarySheet, "A1:G1");
  styleSummarySheet(summarySheet, summaryRows.length, starterHeaderRow);

  const check = await workbook.inspect({
    kind: "table",
    range: `Implemented Cards!A1:K${Math.min(rows.length + 3, 16)}`,
    include: "values,formulas",
    tableMaxRows: 16,
    tableMaxCols: 11,
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
    range: "A1:K24",
    scale: 1,
  });
  await fs.writeFile(
    path.join(__dirname, "implemented_cards_preview.png"),
    Buffer.from(await renderCards.arrayBuffer()),
  );
  const renderSummary = await workbook.render({
    sheetName: "Summary",
    range: "A1:G21",
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

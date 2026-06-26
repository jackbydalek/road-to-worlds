import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";
import {
  ARCHETYPES,
  ARCHETYPE_ORDER,
  archetypeFor,
  combatSummary,
  sortCards,
} from "../../tools/export_card_lists.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "../..");
const cardsPath = path.join(repoRoot, "data/content/cards.json");
const outputPath = path.join(__dirname, "road_to_worlds_current_cards.xlsx");

function titleCase(value) {
  return String(value ?? "")
    .split("_")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
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

function rangeAddress(startCol, startRow, colCount, rowCount) {
  return `${columnLetter(startCol)}${startRow}:${columnLetter(startCol + colCount - 1)}${startRow + rowCount - 1}`;
}

function setColumnWidth(sheet, column, px) {
  try {
    sheet.getRange(`${column}:${column}`).format.columnWidthPx = px;
  } catch {
    // Width setters are a display aid; the workbook remains usable if ignored.
  }
}

function merge(sheet, address) {
  try {
    sheet.getRange(address).merge();
  } catch {
    // Merges are cosmetic; keep the value in the first cell if unavailable.
  }
}

function joinList(value) {
  return Array.isArray(value) ? value.join(", ") : "";
}

function safeNumber(value) {
  return value === undefined || value === null || value === "" ? null : Number(value);
}

function kindLabel(card) {
  const kind = card.combat?.kind ?? card.role ?? "";
  return titleCase(kind);
}

function unitStats(card) {
  const combat = card.combat ?? {};
  if (combat.kind !== "unit") return "";
  return `${combat.attack ?? 0}/${combat.health ?? 1}`;
}

function keywords(card) {
  const combat = card.combat ?? {};
  const pieces = [];
  if (Array.isArray(combat.keywords)) pieces.push(...combat.keywords);
  if (combat.ready) pieces.push("ready");
  return pieces.join(", ");
}

function rawEffects(card) {
  const combat = card.combat ?? {};
  const payload = {};
  for (const key of ["effects", "onPlay", "triggers", "abilities"]) {
    if (Array.isArray(combat[key]) && combat[key].length > 0) payload[key] = combat[key];
  }
  return Object.keys(payload).length > 0 ? JSON.stringify(payload) : "";
}

function countBy(items, getter) {
  const counts = new Map();
  for (const item of items) {
    const key = getter(item);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return [...counts.entries()].sort((a, b) => String(a[0]).localeCompare(String(b[0])));
}

function buildCardRows(cards) {
  return sortCards(cards).map((card) => [
    card.name ?? "",
    card.id ?? "",
    ARCHETYPES[archetypeFor(card)] ?? titleCase(card.archetype),
    titleCase(card.rarity ?? ""),
    kindLabel(card),
    titleCase(card.role ?? ""),
    safeNumber(card.cost),
    safeNumber(card.value),
    safeNumber(card.deckLimit),
    unitStats(card),
    safeNumber(card.stats?.speed),
    safeNumber(card.stats?.power),
    safeNumber(card.stats?.consistency),
    safeNumber(card.stats?.interaction),
    safeNumber(card.stats?.resilience),
    safeNumber(card.stats?.advantage),
    keywords(card),
    card.combat?.targetMode ?? "",
    combatSummary(card),
    card.text ?? "",
    joinList(card.tags),
    card.animalType ?? "",
    card.strategy ?? "",
    rawEffects(card),
  ]);
}

function styleCardsSheet(sheet, rowCount, colCount) {
  const lastCol = columnLetter(colCount - 1);
  sheet.showGridLines = false;
  sheet.freezePanes.freezeRows(3);
  sheet.getRange(`A1:${lastCol}${rowCount}`).format = {
    font: { name: "Aptos", size: 10, color: "#1F2937" },
    verticalAlignment: "top",
    wrapText: true,
  };
  sheet.getRange(`A1:${lastCol}1`).format = {
    fill: "#26333F",
    font: { name: "Aptos Display", size: 16, color: "#FFFFFF", bold: true },
    verticalAlignment: "center",
  };
  sheet.getRange(`A2:${lastCol}2`).format = {
    fill: "#EDF4F2",
    font: { name: "Aptos", size: 10, color: "#334155", italic: true },
    verticalAlignment: "center",
  };
  sheet.getRange(`A3:${lastCol}3`).format = {
    fill: "#D8E7E1",
    font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
    borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
  };
  sheet.getRange(`A4:${lastCol}${rowCount}`).format = {
    fill: "#FBFCFD",
    borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
  };
  sheet.getRange(`G4:P${rowCount}`).format.horizontalAlignment = "center";
  sheet.getRange(`A4:A${rowCount}`).format.font = { name: "Aptos", size: 10, color: "#111827", bold: true };
  sheet.getRange(`G4:P${rowCount}`).format.numberFormat = "#,##0";

  const widths = {
    A: 210, B: 185, C: 165, D: 95, E: 95, F: 110, G: 65, H: 70, I: 75, J: 70,
    K: 70, L: 70, M: 100, N: 100, O: 95, P: 90, Q: 130, R: 115, S: 520,
    T: 300, U: 280, V: 115, W: 105, X: 420,
  };
  for (const [column, px] of Object.entries(widths)) setColumnWidth(sheet, column, px);
  try {
    sheet.tables.add(`A3:${lastCol}${rowCount}`, true, "CurrentCards");
  } catch {
    // Filters are convenient, not essential.
  }
  try {
    sheet.getRange(`A1:${lastCol}${rowCount}`).format.autofitRows();
  } catch {
    // Row autofit is cosmetic.
  }
}

function styleSummarySheet(sheet, rowCount) {
  sheet.showGridLines = false;
  sheet.getRange(`A1:H${rowCount}`).format = {
    font: { name: "Aptos", size: 10, color: "#1F2937" },
    verticalAlignment: "top",
    wrapText: true,
  };
  sheet.getRange("A1:H1").format = {
    fill: "#26333F",
    font: { name: "Aptos Display", size: 16, color: "#FFFFFF", bold: true },
  };
  for (const range of ["A4:B4", "D4:E4", "G4:H4", "A13:C13"]) {
    sheet.getRange(range).format = {
      fill: "#D8E7E1",
      font: { name: "Aptos", size: 10, color: "#12302A", bold: true },
      borders: { preset: "outside", style: "thin", color: "#9DB8AE" },
    };
  }
  for (const range of [`A5:B11`, `D5:E11`, `G5:H11`, `A14:C${rowCount}`]) {
    sheet.getRange(range).format = {
      fill: "#FBFCFD",
      borders: { preset: "inside", style: "thin", color: "#E5E7EB" },
    };
  }
  for (const [column, px] of Object.entries({ A: 190, B: 80, C: 80, D: 160, E: 80, F: 45, G: 160, H: 80 })) {
    setColumnWidth(sheet, column, px);
  }
}

async function main() {
  const data = JSON.parse(await fs.readFile(cardsPath, "utf8"));
  const cards = data.cards ?? [];
  const cardRows = buildCardRows(cards);
  const headers = [
    "Name", "Card ID", "Archetype", "Rarity", "Type", "Role", "Cost", "Value", "Deck Limit",
    "Unit Atk/HP", "Speed", "Power", "Consistency", "Interaction", "Resilience", "Advantage",
    "Keywords", "Target Mode", "Implemented Effects", "Design Text", "Tags", "Animal Type",
    "Strategy", "Raw Effect JSON",
  ];

  const workbook = Workbook.create();
  const cardsSheet = workbook.worksheets.add("All Cards");
  const summarySheet = workbook.worksheets.add("Summary");

  const titleRange = rangeAddress(0, 1, headers.length, 1);
  const noteRange = rangeAddress(0, 2, headers.length, 1);
  cardsSheet.getRange(titleRange).values = [[
    "Road to Worlds - Current Card Catalog",
    ...Array(headers.length - 1).fill(""),
  ]];
  cardsSheet.getRange(noteRange).values = [[
    `Source: data/content/cards.json. Generated from current local content. Total cards: ${cards.length}.`,
    ...Array(headers.length - 1).fill(""),
  ]];
  cardsSheet.getRange(rangeAddress(0, 3, headers.length, 1)).values = [headers];
  cardsSheet.getRange(rangeAddress(0, 4, headers.length, cardRows.length)).values = cardRows;
  merge(cardsSheet, titleRange);
  merge(cardsSheet, noteRange);
  styleCardsSheet(cardsSheet, cardRows.length + 3, headers.length);

  const byArchetype = countBy(cards, (card) => ARCHETYPES[archetypeFor(card)] ?? titleCase(card.archetype));
  const byType = countBy(cards, kindLabel);
  const byRarity = countBy(cards, (card) => titleCase(card.rarity ?? ""));
  const maxTopRows = Math.max(byArchetype.length, byType.length, byRarity.length, 7);
  const summaryRows = [
    ["Road to Worlds - Card Catalog Summary", "", "", "", "", "", "", ""],
    ["Source", "data/content/cards.json", "", "Total Cards", cards.length, "", "Generated", new Date().toISOString().slice(0, 10)],
    ["", "", "", "", "", "", "", ""],
    ["Archetype", "Count", "", "Type", "Count", "", "Rarity", "Count"],
  ];
  for (let i = 0; i < maxTopRows; i += 1) {
    summaryRows.push([
      byArchetype[i]?.[0] ?? "", byArchetype[i]?.[1] ?? "", "",
      byType[i]?.[0] ?? "", byType[i]?.[1] ?? "", "",
      byRarity[i]?.[0] ?? "", byRarity[i]?.[1] ?? "",
    ]);
  }
  summaryRows.push(["", "", "", "", "", "", "", ""]);
  summaryRows.push(["Archetype Order", "Cards", "Notes", "", "", "", "", ""]);
  for (const archetypeId of ARCHETYPE_ORDER) {
    const groupCards = cards.filter((card) => archetypeFor(card) === archetypeId);
    summaryRows.push([
      ARCHETYPES[archetypeId],
      groupCards.length,
      groupCards.map((card) => card.name).join(", "),
      "", "", "", "", "",
    ]);
  }

  summarySheet.getRange(rangeAddress(0, 1, 8, summaryRows.length)).values = summaryRows;
  merge(summarySheet, "A1:H1");
  styleSummarySheet(summarySheet, summaryRows.length);

  const check = await workbook.inspect({
    kind: "table",
    range: "All Cards!A1:X18",
    include: "values,formulas",
    tableMaxRows: 18,
    tableMaxCols: 24,
    tableMaxCellChars: 100,
  });
  console.log(check.ndjson);

  const errors = await workbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
    options: { useRegex: true, maxResults: 300 },
    summary: "final formula error scan",
  });
  console.log(errors.ndjson);

  const cardsPreview = await workbook.render({ sheetName: "All Cards", range: "A1:X24", scale: 1, format: "png" });
  await fs.writeFile(path.join(__dirname, "all_cards_preview.png"), Buffer.from(await cardsPreview.arrayBuffer()));
  const summaryPreview = await workbook.render({ sheetName: "Summary", range: "A1:H20", scale: 1, format: "png" });
  await fs.writeFile(path.join(__dirname, "summary_preview.png"), Buffer.from(await summaryPreview.arrayBuffer()));

  const output = await SpreadsheetFile.exportXlsx(workbook);
  await output.save(outputPath);
  console.log(`Wrote ${outputPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

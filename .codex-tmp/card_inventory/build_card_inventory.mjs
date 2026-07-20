import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const workspace = "/Users/jack.bydalek/Documents/Road to Worlds";
const sourcePath = path.join(workspace, "data/cards.json");
const outputDir = path.join(workspace, "outputs/card_inventory_2026-07-18");
const outputPath = path.join(outputDir, "road_to_worlds_implemented_cards.xlsx");
const previewDir = path.join(workspace, ".codex-tmp/card_inventory/previews");

const catalog = JSON.parse(await fs.readFile(sourcePath, "utf8"));
const cards = catalog.cards;
const decks = catalog.decks;

const titleFill = "#17324D";
const headerFill = "#24557A";
const paleBlue = "#EAF2F8";
const paleGold = "#FFF4D6";
const paleGreen = "#E7F4EA";
const paleRose = "#FCE8F1";
const palePurple = "#EEE9FA";
const borderColor = "#CAD6E2";
const bodyFont = "Aptos";
const titleFont = "Aptos Display";

const proper = (value) => value ? value.charAt(0).toUpperCase() + value.slice(1) : "";
const listText = (values) => Array.isArray(values) ? values.map(proper).join(" + ") : "";

const nonHookKeys = new Set([
  "id", "name", "subtitle", "card_type", "archetype", "rare", "recipe",
  "ingredient_types", "attack", "health", "text", "keywords", "discard_cost"
]);

const starterUsage = new Map();
for (const [deckId, deck] of Object.entries(decks)) {
  for (const [cardId, count] of Object.entries(deck.cards)) {
    if (!starterUsage.has(cardId)) starterUsage.set(cardId, []);
    starterUsage.get(cardId).push({ deckId, name: deck.name, count });
  }
}

const cardRows = cards.map((card, index) => {
  const usage = starterUsage.get(card.id) ?? [];
  const hooks = Object.keys(card)
    .filter((key) => !nonHookKeys.has(key))
    .filter((key) => {
      const value = card[key];
      if (Array.isArray(value)) return value.length > 0;
      if (value && typeof value === "object") return Object.keys(value).length > 0;
      return Boolean(value);
    })
    .join(", ");

  return [
    index + 1,
    card.id,
    card.name,
    card.subtitle ?? "",
    proper(card.card_type),
    proper(card.archetype),
    card.rare ? "Yes" : "No",
    null,
    card.attack ?? null,
    card.health ?? null,
    card.card_type === "meal" ? listText(card.recipe) : listText(card.ingredient_types),
    Array.isArray(card.recipe) ? card.recipe.length : 0,
    card.discard_cost ?? 0,
    null,
    Array.isArray(card.keywords) ? card.keywords.map(proper).join(", ") : "",
    card.text ?? "",
    hooks,
    usage.map((item) => item.name).join(", "),
    usage.reduce((sum, item) => sum + item.count, 0),
    "data/cards.json",
  ];
});

const starterRows = [];
for (const [deckId, deck] of Object.entries(decks)) {
  for (const [cardId, count] of Object.entries(deck.cards)) {
    const card = cards.find((item) => item.id === cardId);
    starterRows.push([
      deckId,
      deck.name,
      proper(deck.archetype),
      cardId,
      card?.name ?? "Missing card",
      proper(card?.card_type ?? ""),
      count,
    ]);
  }
}

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const cardSheet = workbook.worksheets.add("Cards");
const deckSheet = workbook.worksheets.add("Starter Decks");

for (const sheet of [summary, cardSheet, deckSheet]) {
  sheet.showGridLines = false;
}

// Summary sheet
summary.mergeCells("A1:H1");
summary.getRange("A1").values = [["Road to Worlds — Implemented Card Catalog"]];
summary.getRange("A1:H1").format = {
  fill: titleFill,
  font: { name: titleFont, size: 20, bold: true, color: "#FFFFFF" },
  verticalAlignment: "center",
};
summary.getRange("A1:H1").format.rowHeight = 34;
summary.mergeCells("A2:H2");
summary.getRange("A2").values = [["Live catalog inventory from data/cards.json (schema v2), verified 2026-07-18"]];
summary.getRange("A2:H2").format = {
  fill: paleBlue,
  font: { name: bodyFont, size: 10, italic: true, color: "#38546A" },
  verticalAlignment: "center",
};
summary.getRange("A2:H2").format.rowHeight = 24;

summary.getRange("A4:B4").values = [["Catalog KPI", "Count"]];
summary.getRange("A5:A7").values = [["Total cards"], ["Used in a starter deck"], ["Not currently in a starter deck"]];
summary.getRange("B5").formulas = [["=COUNTA('Cards'!$B$5:$B$92)"]];
summary.getRange("B6").formulas = [["=COUNTIF('Cards'!$S$5:$S$92,\">0\")"]];
summary.getRange("B7").formulas = [["=B5-B6"]];

summary.getRange("D4:E4").values = [["Card Type", "Count"]];
summary.getRange("D5:D10").values = [["Ingredient"], ["Meal"], ["Tool"], ["Spice"], ["Environment"], ["Chef"]];
for (let row = 5; row <= 10; row++) {
  summary.getRange(`E${row}`).formulas = [[`=COUNTIF('Cards'!$E$5:$E$92,D${row})`]];
}

summary.getRange("G4:H4").values = [["Rarity", "Count"]];
summary.getRange("G5:G8").values = [["Common"], ["Uncommon"], ["Rare"], ["Mythic"]];
for (let row = 5; row <= 8; row++) {
  summary.getRange(`H${row}`).formulas = [[`=COUNTIF('Cards'!$H$5:$H$92,G${row})`]];
}

summary.getRange("A12:B12").values = [["Archetype", "Count"]];
summary.getRange("A13:A18").values = [["Spicy"], ["Hearty"], ["Sweet"], ["Fresh"], ["Funky"], ["Neutral"]];
for (let row = 13; row <= 18; row++) {
  summary.getRange(`B${row}`).formulas = [[`=COUNTIF('Cards'!$F$5:$F$92,A${row})`]];
}

summary.getRange("D12:E12").values = [["Starter Deck", "Total Cards"]];
const starterNames = Object.values(decks).map((deck) => deck.name);
summary.getRange(`D13:D${12 + starterNames.length}`).values = starterNames.map((name) => [name]);
for (let row = 13; row < 13 + starterNames.length; row++) {
  summary.getRange(`E${row}`).formulas = [[`=SUMIF('Starter Decks'!$B$5:$B$79,D${row},'Starter Decks'!$G$5:$G$79)`]];
}

summary.mergeCells("D20:H20");
summary.getRange("D20").values = [["Implementation note"]];
summary.mergeCells("D21:H23");
summary.getRange("D21").values = [["Cards are included when present in the live catalog loaded by ContentCatalog.gd. Campaign rarity and runtime cost are calculated using the same rules as the game code."]];
summary.getRange("D21:H23").format = {
  fill: "#F6F8FA",
  font: { name: bodyFont, size: 10, color: "#44515C" },
  wrapText: true,
  verticalAlignment: "top",
  borders: { preset: "outside", style: "thin", color: borderColor },
};

for (const headerRange of ["A4:B4", "D4:E4", "G4:H4", "A12:B12", "D12:E12", "D20:H20"]) {
  summary.getRange(headerRange).format = {
    fill: headerFill,
    font: { name: bodyFont, size: 10, bold: true, color: "#FFFFFF" },
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: headerFill },
  };
}
for (const bodyRange of ["A5:B7", "D5:E10", "G5:H8", "A13:B18", "D13:E17"]) {
  summary.getRange(bodyRange).format = {
    font: { name: bodyFont, size: 10, color: "#243746" },
    borders: { insideHorizontal: { style: "thin", color: borderColor }, bottom: { style: "thin", color: borderColor } },
  };
}
summary.getRange("B5:B18").format.numberFormat = "#,##0";
summary.getRange("E5:E17").format.numberFormat = "#,##0";
summary.getRange("H5:H8").format.numberFormat = "#,##0";
summary.getRange("A1:H23").format.font.name = bodyFont;
summary.getRange("A:A").format.columnWidth = 24;
summary.getRange("B:B").format.columnWidth = 12;
summary.getRange("C:C").format.columnWidth = 3;
summary.getRange("D:D").format.columnWidth = 24;
summary.getRange("E:E").format.columnWidth = 12;
summary.getRange("F:F").format.columnWidth = 3;
summary.getRange("G:G").format.columnWidth = 18;
summary.getRange("H:H").format.columnWidth = 12;
summary.freezePanes.freezeRows(2);

// Card inventory sheet
cardSheet.mergeCells("A1:T1");
cardSheet.getRange("A1").values = [["Currently Implemented Cards"]];
cardSheet.getRange("A1:T1").format = {
  fill: titleFill,
  font: { name: titleFont, size: 18, bold: true, color: "#FFFFFF" },
  verticalAlignment: "center",
};
cardSheet.getRange("A1:T1").format.rowHeight = 32;
cardSheet.mergeCells("A2:T2");
cardSheet.getRange("A2").values = [["Filter by type, archetype, rarity, or starter-deck usage. Runtime Cost and Campaign Rarity mirror ContentCatalog.gd."]];
cardSheet.getRange("A2:T2").format = {
  fill: paleBlue,
  font: { name: bodyFont, size: 10, italic: true, color: "#38546A" },
};

const cardHeaders = [
  "#", "Card ID", "Name", "Subtitle", "Card Type", "Archetype", "Rare Flag",
  "Campaign Rarity", "Attack", "Health", "Recipe / Ingredient Types", "Recipe Cost",
  "Discard Cost", "Runtime Cost", "Keywords", "Rules Text", "Implementation Hooks",
  "Starter Decks", "Starter Copies", "Source"
];
cardSheet.getRange("A4:T4").values = [cardHeaders];
cardSheet.getRange("A5:T92").values = cardRows;
cardSheet.getRange("H5").formulas = [["=IF(E5=\"Chef\",\"Mythic\",IF(G5=\"Yes\",\"Rare\",IF(OR(E5=\"Meal\",E5=\"Spice\",E5=\"Environment\"),\"Uncommon\",\"Common\")))"]];
cardSheet.getRange("H5:H92").fillDown();
cardSheet.getRange("N5").formulas = [["=IF(E5=\"Meal\",L5,M5)"]];
cardSheet.getRange("N5:N92").fillDown();

const cardTable = cardSheet.tables.add("A4:T92", true, "ImplementedCardsTable");
cardTable.style = "TableStyleMedium2";
cardTable.showBandedRows = true;
cardTable.showFilterButton = true;

cardSheet.getRange("A4:T4").format = {
  fill: headerFill,
  font: { name: bodyFont, size: 9, bold: true, color: "#FFFFFF" },
  wrapText: true,
  verticalAlignment: "center",
};
cardSheet.getRange("A4:T4").format.rowHeight = 32;
cardSheet.getRange("A5:T92").format.font = { name: bodyFont, size: 9, color: "#243746" };
cardSheet.getRange("A5:A92").format.numberFormat = "0";
cardSheet.getRange("I5:J92").format.numberFormat = "0";
cardSheet.getRange("L5:N92").format.numberFormat = "0";
cardSheet.getRange("S5:S92").format.numberFormat = "0";
cardSheet.getRange("A5:A92").format.horizontalAlignment = "center";
cardSheet.getRange("G5:J92").format.horizontalAlignment = "center";
cardSheet.getRange("L5:N92").format.horizontalAlignment = "center";
cardSheet.getRange("S5:S92").format.horizontalAlignment = "center";
cardSheet.getRange("P5:R92").format.wrapText = true;
cardSheet.getRange("P5:R92").format.verticalAlignment = "top";

cardSheet.getRange("F5:F92").conditionalFormats.add("containsText", { text: "Spicy", format: { fill: "#FCE8E2", font: { color: "#A33B1F" } } });
cardSheet.getRange("F5:F92").conditionalFormats.add("containsText", { text: "Hearty", format: { fill: paleGold, font: { color: "#76551B" } } });
cardSheet.getRange("F5:F92").conditionalFormats.add("containsText", { text: "Sweet", format: { fill: paleRose, font: { color: "#9C376F" } } });
cardSheet.getRange("F5:F92").conditionalFormats.add("containsText", { text: "Fresh", format: { fill: paleGreen, font: { color: "#2F7040" } } });
cardSheet.getRange("F5:F92").conditionalFormats.add("containsText", { text: "Funky", format: { fill: palePurple, font: { color: "#55408C" } } });
cardSheet.getRange("H5:H92").conditionalFormats.add("containsText", { text: "Rare", format: { fill: paleGold, font: { bold: true, color: "#76551B" } } });
cardSheet.getRange("H5:H92").conditionalFormats.add("containsText", { text: "Mythic", format: { fill: palePurple, font: { bold: true, color: "#55408C" } } });

const widths = [5, 31, 26, 24, 13, 13, 10, 17, 8, 8, 24, 11, 12, 12, 20, 58, 31, 34, 12, 18];
for (let i = 0; i < widths.length; i++) {
  cardSheet.getRangeByIndexes(0, i, 92, 1).format.columnWidth = widths[i];
}
for (let i = 0; i < cards.length; i++) {
  const textLength = (cards[i].text ?? "").length;
  const rowHeight = textLength > 160 ? 60 : (textLength > 100 ? 45 : 30);
  cardSheet.getRange(`A${i + 5}:T${i + 5}`).format.rowHeight = rowHeight;
}
cardSheet.freezePanes.freezeRows(4);
cardSheet.freezePanes.freezeColumns(3);

// Starter deck detail sheet
deckSheet.mergeCells("A1:G1");
deckSheet.getRange("A1").values = [["Starter Deck Coverage"]];
deckSheet.getRange("A1:G1").format = {
  fill: titleFill,
  font: { name: titleFont, size: 18, bold: true, color: "#FFFFFF" },
  verticalAlignment: "center",
};
deckSheet.getRange("A1:G1").format.rowHeight = 32;
deckSheet.mergeCells("A2:G2");
deckSheet.getRange("A2").values = [["One row per card entry in each implemented 30-card starter deck."]];
deckSheet.getRange("A2:G2").format = {
  fill: paleBlue,
  font: { name: bodyFont, size: 10, italic: true, color: "#38546A" },
};
deckSheet.getRange("A4:G4").values = [["Deck ID", "Deck Name", "Archetype", "Card ID", "Card Name", "Card Type", "Count"]];
const deckEndRow = 4 + starterRows.length;
deckSheet.getRange(`A5:G${deckEndRow}`).values = starterRows;
const deckTable = deckSheet.tables.add(`A4:G${deckEndRow}`, true, "StarterDeckEntriesTable");
deckTable.style = "TableStyleMedium2";
deckTable.showBandedRows = true;
deckTable.showFilterButton = true;
deckSheet.getRange("A4:G4").format = {
  fill: headerFill,
  font: { name: bodyFont, size: 9, bold: true, color: "#FFFFFF" },
};
deckSheet.getRange(`A5:G${deckEndRow}`).format.font = { name: bodyFont, size: 9, color: "#243746" };
deckSheet.getRange(`G5:G${deckEndRow}`).format.numberFormat = "0";
deckSheet.getRange(`G5:G${deckEndRow}`).format.horizontalAlignment = "center";
const deckWidths = [29, 20, 13, 31, 27, 13, 9];
for (let i = 0; i < deckWidths.length; i++) {
  deckSheet.getRangeByIndexes(0, i, deckEndRow, 1).format.columnWidth = deckWidths[i];
}
deckSheet.freezePanes.freezeRows(4);

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

const summaryPreview = await workbook.render({ sheetName: "Summary", range: "A1:H23", scale: 1.5, format: "png" });
await fs.writeFile(path.join(previewDir, "summary.png"), new Uint8Array(await summaryPreview.arrayBuffer()));
const cardsPreview = await workbook.render({ sheetName: "Cards", range: "A1:T18", scale: 1, format: "png" });
await fs.writeFile(path.join(previewDir, "cards.png"), new Uint8Array(await cardsPreview.arrayBuffer()));
const longRulesPreview = await workbook.render({ sheetName: "Cards", range: "O20:R50", scale: 1.5, format: "png" });
await fs.writeFile(path.join(previewDir, "cards_long_rules.png"), new Uint8Array(await longRulesPreview.arrayBuffer()));
const decksPreview = await workbook.render({ sheetName: "Starter Decks", range: "A1:G24", scale: 1.25, format: "png" });
await fs.writeFile(path.join(previewDir, "starter_decks.png"), new Uint8Array(await decksPreview.arrayBuffer()));

const summaryInspect = await workbook.inspect({
  kind: "table",
  range: "Summary!A1:H23",
  include: "values,formulas",
  tableMaxRows: 25,
  tableMaxCols: 8,
});
console.log("SUMMARY_INSPECT");
console.log(summaryInspect.ndjson);

const cardsInspect = await workbook.inspect({
  kind: "table",
  range: "Cards!A4:T10",
  include: "values,formulas",
  tableMaxRows: 10,
  tableMaxCols: 20,
});
console.log("CARDS_INSPECT");
console.log(cardsInspect.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
});
console.log("FORMULA_ERRORS");
console.log(errors.ndjson);

const xlsx = await SpreadsheetFile.exportXlsx(workbook);
await xlsx.save(outputPath);
console.log(`OUTPUT=${outputPath}`);
console.log(`CARD_COUNT=${cards.length}`);
console.log(`STARTER_ROWS=${starterRows.length}`);

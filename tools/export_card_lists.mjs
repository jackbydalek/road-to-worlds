import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const repoRoot = path.resolve(path.dirname(__filename), "..");
const cardsPath = path.join(repoRoot, "data/content/cards.json");
const outputDir = path.join(repoRoot, "outputs/card-design-review");
const markdownPath = path.join(outputDir, "current_card_list.md");

export const ARCHETYPES = {
  flightless_birds: "Flightless Birds Aggro",
  snake: "Snake Control",
  oxen: "Oxen Ramp",
  glires: "Glires Propagate",
  insect: "Insect Revive",
  neutral: "Universal / Neutral",
};

export const ARCHETYPE_ORDER = [
  "flightless_birds",
  "snake",
  "oxen",
  "glires",
  "insect",
  "neutral",
];

const TARGET_LABELS = {
  selected: "selected target",
  enemy_player: "opponent",
  self_player: "you",
  enemy_unit: "enemy unit",
  all_enemy_units: "all enemy units",
  best_enemy_unit: "best enemy unit",
  all_friendly_units: "all friendly units",
  best_friendly_unit: "best friendly unit",
  source_unit: "this",
};

const TIMING_LABELS = {
  start_turn: "start of your turn",
  end_turn: "end of your turn",
  on_death: "when this dies",
  on_damage_player: "when this damages the opponent",
  opponent_draw: "when opponent draws",
  on_card_played: "when a card is played",
};

function titleCase(value) {
  return String(value ?? "")
    .split("_")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function targetLabel(target) {
  return TARGET_LABELS[target] ?? titleCase(target);
}

function amountLabel(effect) {
  if (effect.amountSource === "source_attack") return "equal to this unit's attack";
  if (effect.amountSource === "enemy_hand_size") return "equal to opponent's hand size";
  if (effect.amountSource) return titleCase(effect.amountSource);
  if (effect.amount !== undefined) return String(effect.amount);
  return "1";
}

function damageAmountLabel(effect) {
  if (effect.amountSource === "source_attack") return "damage equal to this unit's attack";
  if (effect.amountSource === "enemy_hand_size") return "damage equal to opponent's hand size";
  return `${amountLabel(effect)} damage`;
}

function conditionLabel(effectOrTrigger) {
  const condition = effectOrTrigger.condition;
  if (!condition) return "";
  const amount = effectOrTrigger.conditionAmount;
  const labels = {
    relevant_tech: "if this is relevant tech",
    controls_tool: "if you control a tool",
    enemy_discard_at_least: `if opponent has at least ${amount ?? "N"} cards in discard`,
    played_card_cost: `if the played card costs ${amount ?? "N"}`,
    played_card_animal_type: `if the played card is ${titleCase(effectOrTrigger.conditionValue ?? "")}`,
    source_animal_type: `if this is ${titleCase(effectOrTrigger.conditionValue ?? "")}`,
    controls_animal_type: `if you control at least ${amount ?? "N"} ${titleCase(effectOrTrigger.conditionValue ?? "")}`,
    enemy_controls_animal_type: `if opponent controls at least ${amount ?? "N"} ${titleCase(effectOrTrigger.conditionValue ?? "")}`,
  };
  return labels[condition] ?? `if ${titleCase(condition).toLowerCase()}`;
}

function effectLabel(effect) {
  const condition = conditionLabel(effect);
  const suffix = condition ? ` (${condition})` : "";
  const target = targetLabel(effect.target);
  switch (effect.type) {
    case "damage":
      return `Deal ${damageAmountLabel(effect)} to ${target}${suffix}`;
    case "heal":
      return `Heal ${amountLabel(effect)} to ${target}${suffix}`;
    case "draw":
      return `Draw ${amountLabel(effect)}${suffix}`;
    case "discard":
      return `${target === "you" ? "Discard" : "Make " + target + " discard"} ${amountLabel(effect)}${suffix}`;
    case "buff": {
      const attack = Number(effect.amount_attack ?? 0);
      const health = Number(effect.amount_health ?? 0);
      return `Give ${formatStats(attack, health)} to ${target}${suffix}`;
    }
    case "debuff": {
      const attack = -Number(effect.amount_attack ?? 0);
      const health = -Number(effect.amount_health ?? 0);
      return `Give ${formatStats(attack, health)} to ${target}${suffix}`;
    }
    case "destroy":
      return `Destroy ${target}${suffix}`;
    case "exhaust": {
      const turns = effect.turns ? ` for ${effect.turns} turn${effect.turns === 1 ? "" : "s"}` : "";
      return `Exhaust ${target}${turns}${suffix}`;
    }
    case "summon": {
      const ready = effect.ready ? ", ready" : "";
      const tags = Array.isArray(effect.tags) && effect.tags.length > 0 ? `, ${effect.tags.join("/")}` : "";
      return `Summon ${effect.name ?? "a token"} (${effect.attack ?? 0}/${effect.health ?? 1}${ready}${tags})${suffix}`;
    }
    case "gain_focus": {
      const restricted = effect.restrictedTo ? ` ${ARCHETYPES[effect.restrictedTo] ?? titleCase(effect.restrictedTo)}-restricted` : "";
      return `Gain ${amountLabel(effect)}${restricted} focus this turn${suffix}`;
    }
    case "recover":
      return `Recover ${amountLabel(effect)} card${String(amountLabel(effect)) === "1" ? "" : "s"} from discard${suffix}`;
    default:
      return `${titleCase(effect.type)}${suffix}`;
  }
}

function formatStats(attack, health) {
  const attackText = attack >= 0 ? `+${attack}` : `${attack}`;
  const healthText = health >= 0 ? `+${health}` : `${health}`;
  return `${attackText}/${healthText}`;
}

function effectsList(effects = []) {
  if (!Array.isArray(effects) || effects.length === 0) return "";
  return effects.map(effectLabel).join("; ");
}

function triggerLabel(trigger) {
  const timing = TIMING_LABELS[trigger.timing] ?? titleCase(trigger.timing).toLowerCase();
  const condition = conditionLabel(trigger);
  const once = trigger.oncePerTurn ? "Once each turn, " : "";
  const when = condition ? `${timing}, ${condition}` : timing;
  const event = titleCase(when);
  const eventText = once ? event.charAt(0).toLowerCase() + event.slice(1) : event;
  return `${once}${eventText}: ${effectsList(trigger.effects)}.`;
}

function abilityLabel(ability) {
  const cost = ability.cost ?? 0;
  const once = ability.oncePerTurn ? " once each turn" : "";
  const preventAttack = ability.preventAttack ? "; this cannot attack this turn" : "";
  const ready = ability.requiresReady ? "; requires ready" : "";
  return `Activate ${ability.label ?? ability.id ?? "ability"} (cost ${cost}${once}${preventAttack}${ready}): ${effectsList(ability.effects)}.`;
}

export function combatSummary(card) {
  const combat = card.combat ?? {};
  const lines = [];

  if (combat.kind === "unit") {
    const keywords = Array.isArray(combat.keywords) && combat.keywords.length > 0
      ? `; keywords: ${combat.keywords.join(", ")}`
      : "";
    const ready = combat.ready ? "; ready immediately" : "";
    lines.push(`Unit ${combat.attack ?? 0}/${combat.health ?? 1}${keywords}${ready}.`);
  } else if (combat.kind === "action") {
    const targetMode = combat.targetMode ? `; target mode: ${combat.targetMode}` : "";
    lines.push(`Action${targetMode}.`);
  } else if (combat.kind === "engine") {
    lines.push("Engine.");
  } else {
    lines.push(`${titleCase(combat.kind ?? "card")}.`);
  }

  if (Array.isArray(combat.effects) && combat.effects.length > 0) {
    lines.push(`Effects: ${effectsList(combat.effects)}.`);
  }
  if (Array.isArray(combat.onPlay) && combat.onPlay.length > 0) {
    lines.push(`On play: ${effectsList(combat.onPlay)}.`);
  }
  if (Array.isArray(combat.triggers) && combat.triggers.length > 0) {
    for (const trigger of combat.triggers) lines.push(triggerLabel(trigger));
  }
  if (Array.isArray(combat.abilities) && combat.abilities.length > 0) {
    for (const ability of combat.abilities) lines.push(abilityLabel(ability));
  }

  if (lines.length === 1 && combat.kind === "unit") {
    lines.push("No additional implemented effect beyond stats/keywords.");
  }

  return lines.join(" ");
}

export function archetypeFor(card) {
  return ARCHETYPES[card.archetype] ? card.archetype : "neutral";
}

export function sortCards(cards) {
  return [...cards].sort((a, b) => {
    const groupA = ARCHETYPE_ORDER.indexOf(archetypeFor(a));
    const groupB = ARCHETYPE_ORDER.indexOf(archetypeFor(b));
    if (groupA !== groupB) return groupA - groupB;
    const rarityOrder = { common: 0, uncommon: 1, rare: 2, mythic: 3 };
    const rarityA = rarityOrder[a.rarity] ?? 99;
    const rarityB = rarityOrder[b.rarity] ?? 99;
    if (rarityA !== rarityB) return rarityA - rarityB;
    return Number(a.cost ?? 0) - Number(b.cost ?? 0) || String(a.name).localeCompare(String(b.name));
  });
}

export function buildRows(cards) {
  return sortCards(cards).map((card) => {
    const combat = card.combat ?? {};
    return {
      archetype: ARCHETYPES[archetypeFor(card)],
      name: card.name,
      id: card.id,
      cost: card.cost,
      rarity: card.rarity,
      kind: combat.kind ?? card.role ?? "",
      role: card.role ?? "",
      designText: card.text ?? "No text yet.",
      implementedEffect: combatSummary(card),
    };
  });
}

export function buildMarkdown(cards) {
  const byArchetype = new Map(ARCHETYPE_ORDER.map((id) => [id, []]));
  for (const card of sortCards(cards)) byArchetype.get(archetypeFor(card)).push(card);

  const lines = [
    "# Road to Worlds Current Card List",
    "",
    `Total cards: ${cards.length}`,
    "",
    "Format: `Name` — cost, rarity, combat kind, card id.",
    "",
    "Each card includes its design text plus the currently implemented combat behavior.",
    "",
  ];

  for (const archetypeId of ARCHETYPE_ORDER) {
    const group = byArchetype.get(archetypeId);
    lines.push(`## ${ARCHETYPES[archetypeId]}`, "");
    for (const card of group) {
      const combat = card.combat ?? {};
      lines.push(`- **${card.name}** — cost ${card.cost}, ${card.rarity}, ${combat.kind ?? card.role}, \`${card.id}\``);
      lines.push(`  - Text: ${card.text ?? "No text yet."}`);
      lines.push(`  - Implemented: ${combatSummary(card)}`);
    }
    lines.push("");
  }

  return lines.join("\n");
}

async function main() {
  const raw = await fs.readFile(cardsPath, "utf8");
  const data = JSON.parse(raw);
  const cards = data.cards ?? [];
  await fs.mkdir(outputDir, { recursive: true });
  await fs.writeFile(markdownPath, buildMarkdown(cards), "utf8");
  console.log(`Wrote ${markdownPath}`);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

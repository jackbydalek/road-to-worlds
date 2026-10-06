import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
export const PROJECT = path.resolve(HERE, '../..');
export const SOURCES = ['data/cards.json', 'data/content/second_helpings.json', 'data/content/tokens.json'];
const TYPES = ['ingredient', 'meal', 'chef', 'tool', 'spice', 'environment'];
const AFFINITIES = ['spicy', 'sweet', 'hearty', 'fresh', 'funky', 'neutral'];
const TRIGGERS = ['effects', 'on_play', 'on_attack', 'on_sacrifice', 'on_turn_start', 'on_move_to_plated', 'on_combat_damage_to_chef'];
const UNIT_TRIGGERS = ['on_play', 'on_attack', 'on_sacrifice', 'on_move_to_plated', 'on_combat_damage_to_chef'];
const ALLOWED_TRIGGERS = { ingredient: UNIT_TRIGGERS, meal: UNIT_TRIGGERS, chef: ['effects'], tool: ['effects'], spice: [], environment: ['on_turn_start'] };
const hash = value => crypto.createHash('sha256').update(typeof value === 'string' ? value : JSON.stringify(value)).digest('hex');
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const fail = (status, message) => { throw Object.assign(new Error(message), { status }); };
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);

function atomicWrite(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temp = `${file}.${crypto.randomUUID()}.tmp`;
  try {
    fs.writeFileSync(temp, text, { flag: 'wx' });
    fs.renameSync(temp, file);
  } finally {
    if (fs.existsSync(temp)) fs.unlinkSync(temp);
  }
}

// Replace just one object, preserving all other cards, deck lists, and formatting.
export function replaceCard(text, id, replacement) {
  const start = /"cards"\s*:\s*\[/.exec(text);
  if (!start) fail(422, 'Card array is missing.');
  let depth = 0, quoted = false, escaped = false, objectStart = -1;
  for (let i = start.index + start[0].length; i < text.length; i++) {
    const ch = text[i];
    if (quoted) {
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === '"') quoted = false;
      continue;
    }
    if (ch === '"') { quoted = true; continue; }
    if (ch === '{' || ch === '[') {
      if (depth === 0 && ch === '{') objectStart = i;
      depth++;
    } else if (ch === '}' || ch === ']') {
      if (depth === 0) break;
      depth--;
      if (depth === 0 && objectStart >= 0) {
        const raw = text.slice(objectStart, i + 1);
        if (JSON.parse(raw).id === id) {
          const indent = text.slice(text.lastIndexOf('\n', objectStart) + 1, objectStart).match(/^\s*/)[0];
          const updated = raw.includes('\n') ? JSON.stringify(replacement, null, 2).replaceAll('\n', `\n${indent}`) : JSON.stringify(replacement);
          const result = text.slice(0, objectStart) + updated + text.slice(i + 1);
          JSON.parse(result);
          return result;
        }
        objectStart = -1;
      }
    }
  }
  fail(404, 'Card no longer exists in its source file.');
}

function mergeShape(shape, value) {
  if (Array.isArray(value)) {
    shape.kind = 'array'; shape.items ||= {};
    for (const item of value) mergeShape(shape.items, item);
  } else if (object(value)) {
    shape.kind = 'object'; shape.fields ||= {};
    for (const [key, child] of Object.entries(value)) mergeShape(shape.fields[key] ||= {}, child);
  } else shape.kind = typeof value;
}

function checkShape(value, shape, location) {
  if (!shape?.kind) fail(422, `${location}: unsupported field. Use a change request for new mechanics.`);
  if (shape.kind === 'array') {
    if (!Array.isArray(value) || value.length > 100) fail(422, `${location} must be a list of at most 100 entries.`);
    value.forEach((child, index) => checkShape(child, shape.items, `${location}[${index + 1}]`));
  } else if (shape.kind === 'object') {
    if (!object(value)) fail(422, `${location} must be an object.`);
    for (const [key, child] of Object.entries(value)) checkShape(child, shape.fields[key], `${location}.${key}`);
  } else if (typeof value !== shape.kind || (shape.kind === 'number' && (!Number.isFinite(value) || Math.abs(value) > 9999))) {
    fail(422, `${location} must be a valid ${shape.kind}.`);
  } else if (typeof value === 'string' && value.length > 12000) fail(422, `${location} is too long.`);
}

export function createStudio(root = PROJECT) {
  const local = path.join(root, 'tools/card-editor/.local');
  const draftsPath = path.join(local, 'drafts.json');
  const requestsPath = path.join(root, 'tools/card-editor/change-requests.json');
  const historyPath = path.join(local, 'history.json');
  const token = crypto.randomBytes(32).toString('hex');
  const optionalRead = (file, fallback) => fs.existsSync(file) ? read(file) : fallback;
  const rows = () => SOURCES.flatMap(source => {
    const data = read(path.join(root, source));
    const set = source.endsWith('tokens.json') ? 'Tokens' : data.expansion?.name || 'Core Set';
    return data.cards.map(card => ({ card, source, set, revision: hash(card) }));
  });
  const initial = rows();
  const reference = read(path.join(HERE, 'reference-schema.json'));
  const shape = { kind: 'object', fields: structuredClone(reference.fields) };
  const effects = new Map();
  const effectShapes = new Map();
  const effectSchema = {};
  const collect = value => {
    if (Array.isArray(value)) value.forEach(collect);
    else if (object(value)) {
      if (value.type) {
        mergeShape(effectSchema, value);
        if (!effects.has(value.type)) effects.set(value.type, structuredClone(value));
        const schema = effectShapes.get(value.type) || {};
        mergeShape(schema, value); effectShapes.set(value.type, schema);
      }
      Object.values(value).forEach(collect);
    }
  };
  // Keep known operations available even after their last card is redesigned.
  reference.effects.forEach(collect);
  for (const row of initial) { mergeShape(shape, row.card); collect(row.card); }
  // Shared effect slots all accept the same resolver operations.
  for (const key of TRIGGERS) shape.fields[key] = { kind: 'array', items: effectSchema };
  shape.fields.abilities.items.fields.effects = { kind: 'array', items: effectSchema };
  for (const key of ['first_time_only', 'once_per_turn']) {
    effectSchema.fields[key] = { kind: 'boolean' };
    for (const schema of effectShapes.values()) schema.fields[key] = { kind: 'boolean' };
  }
  const keywords = ['stalwart', 'hand_trap', 'bodyguard', 'taunt'];

  function validate(card, original) {
    if (!object(card)) fail(422, 'A card definition is required.');
    if (card.id !== original.id) fail(422, 'Card IDs stay fixed so saved decks keep working.');
    if (Boolean(card.is_token) !== Boolean(original.is_token)) fail(422, 'Token status cannot be changed.');
    checkShape(card, shape, 'Card');
    if (!card.name?.trim()) fail(422, 'Give the card a name.');
    if (!TYPES.includes(card.card_type)) fail(422, 'Choose a supported card type.');
    if (!AFFINITIES.includes(card.archetype)) fail(422, 'Choose a supported affinity.');
    for (const trigger of TRIGGERS) if (card[trigger]?.length && !ALLOWED_TRIGGERS[card.card_type].includes(trigger)) fail(422, `${trigger} does not run on ${card.card_type} cards. Choose a supported trigger or save a change request.`);
    const nonnegative = ['attack', 'discard_cost', 'attack_bonus', 'health_bonus', 'opponent_healing_reduction', 'self_attack_per_friendly_prep_archetype', 'meal_attack_bonus', 'meal_health_bonus', 'ingredient_growth', 'draw_on_attached_attack'];
    for (const key of nonnegative) if (key in card && (!Number.isInteger(card[key]) || card[key] < 0)) fail(422, `${key} must be a nonnegative whole number.`);
    if (['ingredient', 'meal'].includes(card.card_type)) {
      if (card.archetype === 'neutral') fail(422, 'Ingredients and Meals need a non-neutral affinity for their game card frame.');
      if (!Number.isInteger(card.attack) || card.attack < 0) fail(422, 'Units need an Attack of zero or more.');
      if (!Number.isInteger(card.health) || card.health < 1) fail(422, 'Units need at least 1 Health.');
    }
    if (card.card_type === 'meal' && !card.recipe?.length) fail(422, 'Meals need a normal recipe.');
    for (const key of ['archetypes', 'ingredient_types']) if (card[key]?.some(x => !AFFINITIES.includes(x))) fail(422, `${key} contains an unknown affinity.`);
    if (card.archetypes?.length && !card.archetypes.includes(card.archetype)) fail(422, 'Affinities must include the primary affinity.');
    if (card.keywords?.some(x => !keywords.includes(x))) fail(422, 'Unknown keyword. Save a change request for new mechanics.');
    const recipe = values => {
      for (const value of values || []) if (value.split('|').some(x => ![...AFFINITIES, 'any'].includes(x))) fail(422, `Unknown recipe requirement: ${value}`);
    };
    recipe(card.recipe); recipe(card.special_serve?.recipe);
    if (card.art_frame_duration !== undefined && (!(card.art_frame_duration >= 0.02) || card.art_frame_duration > 60)) fail(422, 'Frame duration must be between 0.02 and 60 seconds.');
    for (const asset of [...(card.art_frames || []), ...(card.art_path ? [card.art_path] : [])]) {
      if (!asset.startsWith('res://assets/cards/')) fail(422, 'Artwork must live in assets/cards.');
      const full = safeFile(root, asset.slice(6));
      if (!full || !fs.existsSync(full) || !/\.(png|jpg|jpeg|webp|svg)$/i.test(full)) fail(422, `Artwork not found: ${asset}`);
    }
    const walk = value => {
      if (Array.isArray(value)) value.forEach(walk);
      else if (object(value)) {
        if (value.type) {
          if (!effectShapes.has(value.type)) fail(422, `Effect “${value.type}” needs game code. Save it as a change request.`);
          checkShape(value, effectShapes.get(value.type), `Effect ${value.type}`);
          for (const [key, child] of Object.entries(value)) if (typeof child === 'number' && !Number.isInteger(child)) fail(422, `Effect ${key} must be a whole number.`);
          if (value.amount !== undefined && value.amount < 0) fail(422, 'Effect amounts cannot be negative.');
          if (value.token_id && !rows().some(row => row.card.id === value.token_id && row.card.is_token)) fail(422, 'Choose an existing token ID.');
          if (value.archetype && !AFFINITIES.includes(value.archetype)) fail(422, 'Unknown effect affinity.');
          if (value.card_type && !TYPES.includes(value.card_type)) fail(422, 'Unknown effect card type.');
          if (value.card_types?.some(x => !TYPES.includes(x))) fail(422, 'Unknown effect card type.');
          if (value.zone && !['prep', 'plated'].includes(value.zone)) fail(422, 'Unknown effect destination zone.');
          if (value.target && value.target !== 'selected') fail(422, 'Unknown effect target.');
        }
        Object.values(value).forEach(walk);
      }
    };
    walk(card);
    for (const ability of card.abilities || []) {
      if (!['ingredient', 'meal', 'environment'].includes(card.card_type)) fail(422, 'This card type does not support activated abilities.');
      if (!ability.id?.trim() || ability.timing !== 'activated') fail(422, 'Abilities need an ID and activated timing.');
      if (ability.active_zone && !['prep', 'plated', 'environment'].includes(ability.active_zone)) fail(422, 'Unknown ability zone.');
      if (card.card_type === 'environment' && ability.active_zone !== 'environment') fail(422, 'Environment abilities need the Environment zone.');
      if (card.card_type !== 'environment' && ability.active_zone === 'environment') fail(422, 'Unit abilities need Prep or Plated.');
    }
    return card;
  }

  function catalog() {
    const drafts = optionalRead(draftsPath, {});
    return { token, cards: rows().map(row => {
      const paths = [...(row.card.art_frames || []), row.card.art_path].filter(Boolean);
      const art = paths.find(asset => asset !== 'res://assets/cards/art_pending.png' && safeFile(root, asset.slice(6)) && fs.existsSync(path.join(root, asset.slice(6))));
      return { ...row, art: art || 'res://assets/cards/art_pending.png', artReady: Boolean(art), draft: drafts[row.card.id] || null };
    }), requests: optionalRead(requestsPath, { requests: [] }).requests,
    history: optionalRead(historyPath, []).slice(-30).reverse(),
    types: TYPES, affinities: AFFINITIES, keywords, triggers: TRIGGERS, effectTemplates: [...effects.values()], effectSchemas: Object.fromEntries(effectShapes), schema: shape };
  }

  function getRow(id) { return rows().find(row => row.card.id === id) || fail(404, 'Card not found.'); }
  function checkRevision(row, revision) {
    if (row.revision !== revision) fail(409, 'This card changed in the game since your draft began. Reload the library and compare the latest card before applying. Your draft is still saved.');
  }
  function applyCard(row, card, kind) {
    const file = path.join(root, row.source);
    const before = fs.readFileSync(file, 'utf8');
    const latest = JSON.parse(before).cards.find(card => card.id === row.card.id);
    if (!latest || hash(latest) !== row.revision) fail(409, 'This card changed just before saving. Reload the library and compare your draft.');
    const after = replaceCard(before, row.card.id, card);
    const history = optionalRead(historyPath, []);
    const id = crypto.randomUUID();
    const backup = path.join(local, 'backups', `${id}.json`);
    // Backup is durable before replacing game data. Each request writes one source.
    atomicWrite(backup, before);
    const record = { id, cardId: card.id, name: card.name, source: row.source, before: row.card, after: card, at: new Date().toISOString(), kind };
    atomicWrite(file, after);
    atomicWrite(historyPath, JSON.stringify([...history, record], null, 2) + '\n');
    return record;
  }

  function mutate(route, body) {
    if (route === '/api/upload') {
      if (typeof body.data !== 'string' || body.data.length > 16_000_000) fail(422, 'Choose a PNG smaller than 12 MB.');
      const buffer = Buffer.from(body.data, 'base64');
      if (buffer.length < 24 || !buffer.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) fail(422, 'Choose a valid PNG image.');
      const width = buffer.readUInt32BE(16), height = buffer.readUInt32BE(20);
      if (!width || !height || width > 8192 || height > 8192) fail(422, 'PNG dimensions must be between 1 and 8192 pixels.');
      const relative = `assets/cards/art/editor/${hash(buffer).slice(0, 24)}.png`;
      const file = path.join(root, relative);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      if (!fs.existsSync(file)) fs.writeFileSync(file, buffer, { flag: 'wx' });
      return { path: `res://${relative}` };
    }
    if (route === '/api/undo') {
      const history = optionalRead(historyPath, []);
      const record = history.find(entry => entry.id === body.historyId);
      if (!record) fail(404, 'Change not found.');
      const row = getRow(record.cardId);
      if (!equal(row.card, record.after)) fail(409, 'This card has newer game edits. Undo would overwrite them.');
      applyCard(row, record.before, 'undo');
      return { ok: true };
    }
    const row = getRow(body.id);
    if (route === '/api/request') {
      if (typeof body.note !== 'string' || !body.note.trim() || body.note.length > 12000) fail(422, 'Write a short description of the change you want.');
      const data = optionalRead(requestsPath, { requests: [] });
      data.requests.push({ id: crypto.randomUUID(), cardId: row.card.id, cardName: row.card.name, source: row.source, status: 'pending', note: body.note.trim(), currentCard: row.card, createdAt: new Date().toISOString() });
      atomicWrite(requestsPath, JSON.stringify(data, null, 2) + '\n');
      return { ok: true };
    }
    if (!['/api/draft', '/api/discard', '/api/apply', '/api/validate'].includes(route)) fail(404, 'Unknown action.');
    const drafts = optionalRead(draftsPath, {});
    if (route === '/api/discard') {
      if ((drafts[body.id]?.version || null) !== (body.draftVersion || null)) fail(409, 'This draft changed in another window. Reload first.');
      delete drafts[body.id]; atomicWrite(draftsPath, JSON.stringify(drafts, null, 2) + '\n');
      return { ok: true };
    }
    validate(body.card, row.card);
    if (route === '/api/validate') { checkRevision(row, body.baseRevision); return { ok: true }; }
    if ((drafts[body.id]?.version || null) !== (body.draftVersion || null)) fail(409, 'This draft changed in another window. Reload before saving.');
    if (route === '/api/draft') {
      // Conflicted drafts may still be saved; applying always requires a current base.
      if (typeof body.baseRevision !== 'string') fail(422, 'Draft revision is missing.');
      drafts[body.id] = { card: body.card, baseRevision: body.baseRevision, baseCard: drafts[body.id]?.baseCard || row.card, version: crypto.randomUUID(), savedAt: new Date().toISOString() };
      atomicWrite(draftsPath, JSON.stringify(drafts, null, 2) + '\n');
      return drafts[body.id];
    }
    checkRevision(row, body.baseRevision);
    if (equal(row.card, body.card)) fail(422, 'There are no card changes to apply.');
    const record = applyCard(row, body.card, 'apply');
    delete drafts[body.id]; atomicWrite(draftsPath, JSON.stringify(drafts, null, 2) + '\n');
    return { ok: true, record };
  }

  return { catalog, mutate, validate, token, root };
}

function safeFile(root, relative) {
  const target = path.resolve(root, relative);
  if (!target.startsWith(path.resolve(root) + path.sep)) return null;
  if (fs.existsSync(target) && !fs.realpathSync(target).startsWith(fs.realpathSync(root) + path.sep)) return null;
  return target;
}

export function createServer(studio = createStudio()) {
  return http.createServer(async (req, res) => {
    const json = (status, body) => { res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(body)); };
    try {
      const port = req.socket.localPort;
      const hosts = [`127.0.0.1:${port}`, `localhost:${port}`];
      if (!hosts.includes(req.headers.host)) fail(403, 'Open Card Studio from its local address.');
      if (req.headers.origin && !hosts.map(host => `http://${host}`).includes(req.headers.origin)) fail(403, 'Cross-site requests are not allowed.');
      if (req.headers['sec-fetch-site'] === 'cross-site') fail(403, 'Cross-site requests are not allowed.');
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('Content-Security-Policy', "default-src 'self'; img-src 'self' blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; font-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'");
      const route = new URL(req.url, `http://${req.headers.host}`).pathname;
      if (req.method === 'POST' && route.startsWith('/api/')) {
        if (req.headers['x-studio-token'] !== studio.token) fail(403, 'Reload Card Studio to reconnect.');
        if (!req.headers['content-type']?.startsWith('application/json')) fail(415, 'Send JSON.');
        const chunks = []; let length = 0;
        for await (const chunk of req) { length += chunk.length; if (length > 17_000_000) fail(413, 'Request is too large.'); chunks.push(chunk); }
        let body;
        try { body = JSON.parse(Buffer.concat(chunks).toString()); } catch { fail(400, 'Invalid JSON.'); }
        if (!object(body)) fail(400, 'Send an object.');
        return json(200, studio.mutate(route, body));
      }
      if (!['GET', 'HEAD'].includes(req.method)) fail(405, 'Method not supported.');
      if (route === '/api/catalog') return json(200, studio.catalog());
      if (route === '/palette.css') {
        const source = fs.readFileSync(path.join(studio.root, 'scripts/ui/GamePalette.gd'), 'utf8');
        const tokens = [...source.matchAll(/const (\w+)\s*:=\s*Color\("(#[0-9A-Fa-f]+)"\)/g)].map(([, name, value]) => `--${name.toLowerCase().replaceAll('_', '-')}:${value};`).join('');
        res.writeHead(200, { 'Content-Type': 'text/css', 'Cache-Control': 'no-store' }); return res.end(`:root{${tokens}}`);
      }
      let file;
      if (['/', '/index.html', '/app.js', '/style.css'].includes(route)) file = path.join(HERE, 'dist', route === '/' ? 'index.html' : route.slice(1));
      else if (/^\/assets\/(cards\/|fonts\/|logos\/|ui\/locals-card-club-mark\.svg$)/.test(route)) {
        const decoded = decodeURIComponent(route.slice(1));
        if (!/\.(png|jpe?g|webp|svg|ttf|woff2?)$/i.test(decoded)) fail(404, 'Asset not found.');
        file = safeFile(studio.root, decoded);
        if (file && !/^assets\/(cards|fonts|logos)\/|^assets\/ui\/locals-card-club-mark\.svg$/.test(path.relative(studio.root, file))) file = null;
      }
      if (!file || !fs.existsSync(file) || !fs.statSync(file).isFile()) fail(404, 'Not found.');
      const mime = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.woff': 'font/woff', '.woff2': 'font/woff2' };
      res.writeHead(200, { 'Content-Type': mime[path.extname(file).toLowerCase()], 'Cache-Control': file.includes(`${path.sep}assets${path.sep}`) ? 'max-age=60' : 'no-store' });
      if (req.method === 'HEAD') return res.end();
      fs.createReadStream(file).on('error', () => res.destroy()).pipe(res);
    } catch (error) { if (!res.headersSent) json(error.status || 500, { error: error.status ? error.message : 'Could not read or save the project. Check the server terminal.' }); else res.destroy(); if (!error.status) console.error(error); }
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.CARD_STUDIO_PORT || 4317);
  const server = createServer();
  server.on('error', error => { console.error(`Card Studio could not start: ${error.message}`); process.exitCode = 1; });
  server.listen(port, '127.0.0.1', () => console.log(`Card Studio is ready: http://127.0.0.1:${port}\nKeep this terminal open while editing. Press Ctrl+C to stop.`));
}

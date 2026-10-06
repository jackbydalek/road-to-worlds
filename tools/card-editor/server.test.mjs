import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import http from 'node:http';
import { createStudio, createServer, replaceCard, PROJECT, SOURCES } from './server.mjs';

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'locals-card-studio-test-'));
  for (const source of SOURCES) {
    fs.mkdirSync(path.dirname(path.join(root, source)), { recursive: true });
    fs.copyFileSync(path.join(PROJECT, source), path.join(root, source));
  }
  // Asset validation sees the same existing art, without copying hundreds of frames.
  fs.mkdirSync(path.join(root, 'assets/cards'), { recursive: true });
  const definitions = SOURCES.flatMap(source => JSON.parse(fs.readFileSync(path.join(root, source))).cards);
  for (const card of definitions) for (const asset of [...(card.art_frames || []), ...(card.art_path ? [card.art_path] : [])]) {
    const file = path.join(root, asset.slice(6));
    fs.mkdirSync(path.dirname(file), { recursive: true });
    if (!fs.existsSync(file)) fs.copyFileSync(path.join(PROJECT, asset.slice(6)), file);
  }
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const studio = createStudio(root);
  return { root, studio, get: id => studio.catalog().cards.find(row => row.card.id === id), body: row => ({ id: row.card.id, card: structuredClone(row.card), baseRevision: row.revision, draftVersion: row.draft?.version || null }) };
}

test('all 95 collectibles and the token validate, with existing artwork and effects', () => {
  const studio = createStudio();
  const catalog = studio.catalog();
  assert.equal(catalog.cards.length, 96);
  assert.equal(catalog.cards.filter(row => row.card.is_token).length, 1);
  assert.equal(catalog.effectTemplates.length, 37);
  assert.ok(catalog.cards.some(row => row.artReady));
  for (const row of catalog.cards) assert.ok(fs.existsSync(path.join(PROJECT, row.art.slice(6))));
  for (const row of catalog.cards) studio.validate(row.card, row.card);
});

test('single-card replacements preserve every byte outside the selected object', () => {
  for (const source of SOURCES) {
    const original = fs.readFileSync(path.join(PROJECT, source), 'utf8');
    const card = JSON.parse(original).cards[0];
    const changed = { ...card, name: 'Quotes " and brackets }] and café', text: 'A line\nA second line' };
    const next = replaceCard(original, card.id, changed);
    const expected = JSON.parse(original); expected.cards[0] = changed;
    assert.deepEqual(JSON.parse(next), expected);
    assert.equal(replaceCard(next, card.id, { id: card.id }), replaceCard(original, card.id, { id: card.id }));
  }
});

test('drafts persist across server restarts, apply only their card, and undo preserves other edits', t => {
  const { studio, root, get, body } = fixture(t);
  const row = get('spicy_hot_honey_bee'), request = body(row);
  const before = fs.readFileSync(path.join(root, row.source), 'utf8');
  request.card.attack = 7; request.card.on_play[0].amount = 3;
  const draft = studio.mutate('/api/draft', request);
  assert.equal(fs.readFileSync(path.join(root, row.source), 'utf8'), before);
  assert.equal(createStudio(root).catalog().cards.find(r => r.card.id === row.card.id).draft.card.attack, 7);
  assert.throws(() => studio.mutate('/api/draft', request), /another window/);
  request.draftVersion = draft.version;
  const other = body(get('spicy_jalapeno_jackal'));other.card.attack = 9;
  studio.mutate('/api/apply', other);
  const result = studio.mutate('/api/apply', request);
  assert.equal(get(row.card.id).card.attack, 7);
  assert.equal(get('spicy_jalapeno_jackal').card.attack, 9);
  assert.equal(get(row.card.id).draft, null);
  assert.equal(fs.readFileSync(path.join(root, 'tools/card-editor/.local/backups', `${result.record.id}.json`), 'utf8').includes('"attack":9'), true);
  studio.mutate('/api/undo', { historyId: result.record.id });
  assert.deepEqual(get(row.card.id).card, row.card);
  assert.equal(get('spicy_jalapeno_jackal').card.attack, 9);
});

test('source conflicts and malformed mechanics never overwrite game data', t => {
  const { studio, root, get, body } = fixture(t);
  const row = get('spicy_hot_honey_bee'), stale = body(row), fresh = body(row);
  fresh.card.health = 5;studio.mutate('/api/apply', fresh);
  stale.card.attack = 4;
  assert.throws(() => studio.mutate('/api/apply', stale), /changed in the game/);
  const source = fs.readFileSync(path.join(root, row.source), 'utf8');
  const ignoredTrigger = body(get(row.card.id)); ignoredTrigger.card.effects = [{ type: 'draw', amount: 1 }];
  assert.throws(() => studio.mutate('/api/apply', ignoredTrigger), /does not run/);
  for (const change of [card => card.id='another_id', card => card.health=0, card => card.attack=1.5, card => card.on_play=[{type:'invented_effect'}], card => card.on_play=[{type:'draw',amount:'3'}], card => card.on_play=[{type:'draw',amount:-1}], card => card.art_path='res://../../etc/passwd', card => card.keywords=['unknown_keyword'], card => card.on_play=[{type:'damage_enemy_player',banana:5}]]) {
    const request = body(get(row.card.id));change(request.card);
    assert.throws(() => studio.mutate('/api/apply', request));
    assert.equal(fs.readFileSync(path.join(root, row.source), 'utf8'), source);
  }
});

test('expansion and token edits reach the correct files; requests stay separate', t => {
  const { studio, root, get, body } = fixture(t);
  const core = fs.readFileSync(path.join(root, SOURCES[0]), 'utf8');
  for (const id of ['spicy_jalapenowl', 'token_fresh_ingredient']) {
    const request = body(get(id));request.card.name += ' Test';
    studio.mutate('/api/apply', request);
    assert.equal(get(id).card.name, request.card.name);
  }
  studio.mutate('/api/request', { id:'spicy_jalapenowl', note:'Add a new triggered effect.' });
  assert.equal(studio.catalog().requests[0].status, 'pending');
  assert.equal(fs.readFileSync(path.join(root, SOURCES[0]), 'utf8'), core);
});

test('HTTP requires a local host and authenticated same-origin writes', async t => {
  const { studio, get, body } = fixture(t), server = createServer(studio);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }));
  const url = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(url)).status, 200);
  assert.equal((await fetch(url+'/api/catalog')).status, 200);
  assert.equal((await fetch(url+'/data/cards.json')).status, 404);
  assert.equal((await fetch(url+'/api/catalog',{headers:{Origin:'https://example.com'}})).status, 403);
  const foreignHostStatus = await new Promise((resolve, reject) => {
    http.get(url + '/api/catalog', { headers: { Host: 'evil.example' } }, response => { response.resume(); resolve(response.statusCode); }).on('error', reject);
  });
  assert.equal(foreignHostStatus, 403);
  const request = body(get('spicy_hot_honey_bee'));request.card.attack=5;
  assert.equal((await fetch(url+'/api/apply',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(request)})).status,403);
  assert.equal((await fetch(url+'/api/apply',{method:'POST',headers:{'Content-Type':'application/json','X-Studio-Token':studio.token},body:JSON.stringify(request)})).status,200);
});

test('Godot consumes applied stats, printed text, and damage effects from edited JSON', t => {
  const { studio, root, get, body } = fixture(t);
  const request=body(get('spicy_hot_honey_bee'));
  request.card.attack=7;request.card.health=8;request.card.text='When played, deal 3 damage to the opposing Chef.';request.card.on_play[0].amount=3;
  studio.mutate('/api/apply',request);
  const godot='/Applications/Godot.app/Contents/MacOS/Godot';
  if(!fs.existsSync(godot)){t.skip('Godot is not installed at the standard macOS path.');return;}
  const result=spawnSync(godot,['--headless','--path',PROJECT,'--log-file',path.join(root,'godot.log'),'--script','res://scripts/CardEditorIntegrationSmokeTest.gd','--',path.join(root,SOURCES[0])],{encoding:'utf8',timeout:60000});
  assert.equal(result.status,0,result.stdout+'\n'+result.stderr);
  assert.match(result.stdout,/Card editor integration passed/);
});

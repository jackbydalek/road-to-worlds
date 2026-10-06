const $ = selector => document.querySelector(selector);
const escape = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const clone = value => structuredClone(value);
const same = (a,b) => JSON.stringify(a) === JSON.stringify(b);
const label = value => String(value).replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());
const assetURL = value => value?.startsWith('res://assets/') ? '/' + value.slice(6).split('/').map(encodeURIComponent).join('/') : '/assets/cards/art_pending.png';
const triggerNames = { effects:'When used', on_play:'When played / served', on_attack:'When attacking', on_sacrifice:'When sacrificed', on_turn_start:'At the start of the turn', on_move_to_plated:'When moved to Plated', on_combat_damage_to_chef:'After combat damage to a Chef' };
const names = { text:'Printed effect text', archetype:'Primary affinity', archetypes:'Affinities', ingredient_types:'Ingredient types', discard_cost:'Cards to discard', art_frame_duration:'Seconds per frame', art_frames:'Animation frames', art_path:'Still artwork', active_zone:'Usable in', target:'Target', card_type:'Card type', amount:'Amount', attack:'Attack', health:'Health', rare:'Rare card', is_token:'Token', on_play:'When played', count:'Cards to look at', ingredient_filter:'Ingredient requirements', require_ready:'Ingredients must be ready', extra_any:'Extra ingredients (any)', once_per_turn:'Once per turn', first_time_only:'First time only', timing:'Timing', recipe:'Recipe', exclude_self:'Exclude this card', min_attack:'Minimum Attack', min_health:'Minimum Health' };
let data, current, work, saved, baseRevision, draftVersion, activeTab='details', typeFilter='', affinityFilter='', busy=false, rawError='', note='', animated=false, timer, notice='', pendingAction;
const hasChanges = () => work && !same(work,saved);
const currentRow = () => data?.cards.find(row => row.card.id === current);

async function api(route, body) {
  const response = await fetch(route, body ? {method:'POST',headers:{'Content-Type':'application/json','X-Studio-Token':data.token},body:JSON.stringify(body)} : {cache:'no-store'});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || 'Could not reach Card Studio.');
  return result;
}
function toast(message) { const node=$('#toast');node.textContent=message;node.hidden=false;clearTimeout(toast.timeout);toast.timeout=setTimeout(()=>node.hidden=true,5000); }
async function action(callback) {
  if(busy)return;busy=true;$('main').classList.add('busy');updateFooter();
  try{await callback();}catch(error){notice=error.message;const node=$('#editor-error');if(node){node.textContent=notice;node.hidden=false;}toast(error.message);}finally{busy=false;$('main').classList.remove('busy');updateFooter();}
}
async function load(selectId=current) {
  data=await api('/api/catalog');
  $('#connection').textContent='Connected to your local game';
  $('#total').textContent=data.cards.length;
  $('#request-count').textContent=data.requests.filter(item=>item.status==='pending').length;
  const set=$('#set-filter'), value=set.value;
  set.innerHTML='<option value="">Every set</option>'+[...new Set(data.cards.map(row=>row.set))].map(name=>`<option ${name===value?'selected':''}>${escape(name)}</option>`).join('');
  renderFilters();renderGrid();
  if(selectId && data.cards.some(row=>row.card.id===selectId))selectCard(selectId,true);
}
function renderFilters(){
  $('#type-filters').innerHTML=data.types.map(type=>`<button class="${typeFilter===type?'selected':''}" data-type="${type}">${label(type)}s <span>${data.cards.filter(row=>row.card.card_type===type).length}</span></button>`).join('');
  $('#affinity-filters').innerHTML=data.affinities.map(type=>`<button class="${affinityFilter===type?'selected':''}" data-affinity="${type}"><span class="affinity-dot" style="--affinity:var(--affinity-${type})"></span>${label(type)}</button>`).join('');
  $('#all-cards').classList.toggle('selected',!typeFilter&&!affinityFilter);
}
function affinities(card){return card.archetypes?.length?card.archetypes:card.ingredient_types?.length?card.ingredient_types:[card.archetype||'neutral'];}
function artFor(card){return card.art_frames?.[0]||card.art_path||'res://assets/cards/art_pending.png';}
function preview(card,number,large=false){
  const affinity=data.affinities.includes(card.archetype)?card.archetype:'neutral';
  const unit=['ingredient','meal'].includes(card.card_type);
  const art=artFor(card),ready=art!=='res://assets/cards/art_pending.png';
  const recipe=(card.recipe||[]).map(x=>x.split('|').map(label).join(' / ')).join(' + ');
  return `<div class="mini-card" style="--affinity:var(--affinity-${affinity})"><div class="card-top"><span>${escape(card.name||'Untitled card')}</span><small class="card-number">${String(number).padStart(3,'0')}</small></div><div class="card-art"><img ${large?'id="preview-art"':'loading="lazy"'} src="${assetURL(art)}" alt="${escape(ready?`${card.name} artwork`:'Artwork pending')}" decoding="async">${ready?'':'<span class="pending-tag">Art pending</span>'}</div><div class="card-band"><span>${escape(label(card.card_type||''))}</span><span>${escape(affinities(card).map(label).join(' / '))}</span></div><div class="card-rules"><p>${escape(card.text||'No effect text.')}</p>${large&&recipe?`<p class="muted" style="margin-top:8px">Recipe: ${escape(recipe)}</p>`:''}</div><div class="card-stats">${unit?`<span>${escape(card.attack??0)} <small>ATK</small></span><span>${escape(card.health??0)} <small>HP</small></span>`:`<span>${card.rare?'Rare':card.is_token?'Token':label(card.card_type||'')}</span><span>${card.discard_cost?`${escape(card.discard_cost)} discard`:''}</span>`}</div></div>`;
}
function renderGrid(){
  if(!data)return;
  const query=$('#search').value.trim().replaceAll('_',' ').toLocaleLowerCase(), set=$('#set-filter').value,art=$('#art-filter').value;
  let rows=data.cards.filter(row=>{
    const card=row.draft?.card||row.card;
    return (!typeFilter||card.card_type===typeFilter)&&(!affinityFilter||affinities(card).includes(affinityFilter))&&(!set||row.set===set)&&(!art||(art==='ready')===(artFor(card)!=='res://assets/cards/art_pending.png'))&&(!$('#draft-filter').checked||row.draft)&&(!query||JSON.stringify(card).replaceAll('_',' ').toLocaleLowerCase().includes(query));
  });
  const sort=$('#sort').value;
  if(sort==='name')rows.sort((a,b)=>(a.draft?.card||a.card).name.localeCompare((b.draft?.card||b.card).name));
  else if(sort!=='catalog')rows.sort((a,b)=>((b.draft?.card||b.card)[sort]||0)-((a.draft?.card||a.card)[sort]||0));
  $('#result-count').textContent=`${rows.length} of ${data.cards.length} cards`;
  $('#card-grid').innerHTML=rows.length?rows.map(row=>{
    const card=row.draft?.card||row.card;
    return `<button class="card-entry" data-card="${escape(card.id)}" aria-label="Edit ${escape(card.name)}" aria-pressed="${current===card.id}">${preview(card,data.cards.indexOf(row)+1)}<div class="card-caption"><span>${escape(row.set)}</span>${row.draft?'<span class="draft-dot">Draft</span>':card.rare?'<span>Rare ✦</span>':''}</div></button>`;
  }).join(''):'<div class="empty"><h2>No cards match.</h2><p>Try another name or clear your filters.</p><button id="clear-filters">Clear filters</button></div>';
}
function safeToLeave(){return !(hasChanges()||note.trim()||rawError)||confirm('You have unsaved edits or a request on this card. Discard them and leave?');}
function selectCard(id,force=false){
  if(!force&&id!==current&&!safeToLeave())return;
  if(!force&&id===current){$('#editor').classList.add('open');return;}
  const row=data.cards.find(entry=>entry.card.id===id);if(!row)return;
  clearInterval(timer);current=id;work=clone(row.draft?.card||row.card);saved=clone(work);baseRevision=row.draft?.baseRevision||row.revision;draftVersion=row.draft?.version||null;rawError='';notice='';note='';animated=false;
  renderEditor();renderGrid();$('#editor').classList.add('open');
}
const pathAttr = parts => escape(JSON.stringify(parts));
function get(parts){return parts.reduce((value,key)=>value?.[key],work);}
function set(parts,value){const holder=parts.slice(0,-1).reduce((obj,key)=>obj[key]??=(typeof key==='number'?[]:{}),work);holder[parts.at(-1)]=value;}
function options(values,value){return values.map(item=>`<option value="${escape(item)}" ${same(item,value)?'selected':''}>${escape(label(item))}</option>`).join('');}
function field(parts,value,customName,help){
  const key=parts.at(-1),title=customName||names[key]||label(key),attrs=`data-path="${pathAttr(parts)}"`;
  if(typeof value==='boolean')return `<label class="check"><input type="checkbox" ${attrs} ${value?'checked':''}><span>${escape(title)}</span></label>`;
  let input;
  let choices;
  if(['archetype','attached_archetype','count_archetype','meal_attack_archetype','meal_health_archetype','ingredient_growth_archetype','token_archetype'].includes(key))choices=data.affinities;
  if(key==='card_type')choices=data.types;
  if(['active_zone','zone','hand_trap_guard_zone'].includes(key))choices=['prep','plated','environment'];
  if(key==='timing')choices=['activated'];
  if(key==='side')choices=['friendly','enemy'];
  if(choices&&!choices.includes(value))choices=[value,...choices];
  if(choices)input=`<select ${attrs}>${options(choices,value)}</select>`;
  else if(typeof value==='number')input=`<input type="number" ${attrs} data-kind="number" value="${escape(value)}" step="${key==='art_frame_duration'?'0.01':'1'}">`;
  else if(Array.isArray(value)&&value.every(item=>typeof item==='string'))input=`<input ${attrs} data-kind="list" value="${escape(value.join(', '))}" placeholder="Separate entries with commas">`;
  else if(typeof value==='string')input=key==='text'?`<textarea ${attrs} rows="4">${escape(value)}</textarea>`:`<input ${attrs} value="${escape(value)}">`;
  else if(Array.isArray(value))return `<div class="subfields"><h3>${escape(title)}</h3>${value.map((item,index)=>objectFields([...parts,index],item)).join('')}</div>`;
  else if(value&&typeof value==='object')return `<div class="subfields"><h3>${escape(title)}</h3>${objectFields(parts,value)}</div>`;
  else return '';
  return `<label class="field">${escape(title)}${input}${help?`<small>${escape(help)}</small>`:''}</label>`;
}
function objectFields(parts,value,exclude=[]){return Object.entries(value).filter(([key])=>!exclude.includes(key)).map(([key,value])=>field([...parts,key],value)).join('');}
function detailsForm(){
  const unit=['ingredient','meal'].includes(work.card_type);
  const handled=['id','name','subtitle','text','card_type','archetype','archetypes','ingredient_types','attack','health','rare','keywords','recipe','discard_cost','art_path','art_frames','art_frame_duration','abilities',...data.triggers];
  return `${field(['name'],work.name)}${field(['subtitle'],work.subtitle||'')}<div class="field-row">${field(['card_type'],work.card_type)}${field(['archetype'],work.archetype)}</div>${unit?`<div class="field-row">${field(['attack'],work.attack??0)}${field(['health'],work.health??1)}</div>`:''}${field(['text'],work.text||'',null,'Printed text describes the card. Change its actual behavior in Effects, too.')}${field(['rare'],Boolean(work.rare))}${unit?`<div class="field-section"><h3>Keywords</h3><div class="checks">${data.keywords.map(key=>`<label class="check"><input type="checkbox" data-keyword="${key}" ${(work.keywords||[]).includes(key)?'checked':''}>${label(key)}</label>`).join('')}</div></div>`:''}${work.card_type==='meal'?field(['recipe'],work.recipe||[],null,'One entry per Ingredient. Example: spicy, any. Use spicy|funky for either affinity.'):''}${field(['discard_cost'],work.discard_cost||0)}<details><summary>Affinities & additional rules</summary>${field(['archetypes'],work.archetypes||affinities(work),null,'Keep these aligned with the primary affinity.')}${work.card_type==='ingredient'?field(['ingredient_types'],work.ingredient_types||[work.archetype]):''}${objectFields([],work,handled)}</details><details><summary>Artwork & animation</summary><p class="muted">Choose a replacement PNG, or edit existing artwork paths. A new PNG replaces animation for this card.</p><label class="field">Replace artwork<input type="file" id="upload-art" accept="image/png"></label>${field(['art_path'],work.art_path||'')}${field(['art_frames'],work.art_frames||[],null,'Frames play in this order; leave empty for still artwork.')}${field(['art_frame_duration'],work.art_frame_duration||0.07)}</details>`;
}
function effectGroup(parts,effects,title){
  return `<section class="field-section"><h3>${escape(title)}</h3>${effects.map((effect,index)=>`<div class="effect-block"><div class="effect-title"><strong>${index+1}. ${escape(label(effect.type))}</strong><button type="button" data-remove-effect="${pathAttr([...parts,index])}" aria-label="Remove ${escape(label(effect.type))}">✕</button></div>${objectFields([...parts,index],effect,['type'])}${effectOptions([...parts,index],effect)}</div>`).join('')}<div class="effect-add"><select aria-label="Effect to add to ${escape(title)}" id="effect-${parts.join('-')}">${data.effectTemplates.map(effect=>`<option value="${effect.type}">${escape(label(effect.type))}</option>`).sort().join('')}</select><button data-add-effect="${pathAttr(parts)}">Add</button></div></section>`;
}
function effectOptions(parts,effect){
  const missing=Object.keys(data.effectSchemas[effect.type]?.fields||{}).filter(key=>key!=='type'&&!(key in effect));
  if(!missing.length)return '';
  return `<details><summary>Add a filter or option</summary><div class="effect-add"><select id="option-${parts.join('-')}" aria-label="Effect option">${missing.map(key=>`<option value="${escape(key)}">${escape(names[key]||label(key))}</option>`).join('')}</select><button data-add-option="${pathAttr(parts)}">Add</button></div></details>`;
}
function effectsForm(){
  const groups=data.triggers.filter(key=>work[key]?.length);
  const allowed=['ingredient','meal'].includes(work.card_type)?['on_play','on_attack','on_sacrifice','on_move_to_plated','on_combat_damage_to_chef']:work.card_type==='environment'?['on_turn_start']:['chef','tool'].includes(work.card_type)?['effects']:[];
  const available=allowed.filter(key=>!groups.includes(key));
  return `<p class="muted">These are the effects the game runs, in order. Amounts, targets, and filters are editable below.</p>${groups.map(key=>effectGroup([key],work[key],triggerNames[key])).join('')}${available.length?`<div class="field-section"><h3>Add a trigger</h3><div class="effect-add"><select id="new-trigger" aria-label="New effect trigger">${available.map(key=>`<option value="${key}">${triggerNames[key]}</option>`).join('')}</select><button id="add-trigger">Add</button></div></div>`:''}${(work.abilities||[]).map((ability,index)=>`<section class="field-section"><div class="effect-title"><h3>Activated ability ${index+1}</h3><button data-remove-ability="${index}">Remove</button></div>${objectFields(['abilities',index],ability,['effects'])}${effectGroup(['abilities',index,'effects'],ability.effects||[],'Ability effects')}</section>`).join('')}${['ingredient','meal','environment'].includes(work.card_type)?'<button id="add-ability">+ Activated ability</button>':''}<details ${work.card_type==='spice'?'open':''}><summary>Passive rules & special conditions</summary>${objectFields([],work,['id','name','subtitle','text','card_type','archetype','archetypes','ingredient_types','attack','health','rare','recipe','art_path','art_frames','art_frame_duration','abilities',...data.triggers])}</details><p class="muted">For a mechanic that is not available yet, leave a change request.</p>`;
}
function renderEditor(){
  if(!current)return;
  clearInterval(timer);const row=currentRow();
  $('#editor').innerHTML=`<div class="editor-heading"><div><div class="section-label">EDIT CARD</div><h2 id="editor-name">${escape(work.name)}</h2><div class="muted">${escape(work.id)}</div></div><button class="editor-close quiet" id="close-editor" aria-label="Close card editor">✕</button></div><div class="editor-scroll"><div id="editor-error" class="error" ${notice?'':'hidden'}>${escape(notice)}</div>${baseRevision!==row.revision?'<div class="error">This draft started before another game edit. Review both versions before applying.<div class="conflict-actions"><button id="resolve-conflict">Compare with current game</button></div></div>':''}<div class="preview-stage" id="preview-stage">${preview(work,data.cards.indexOf(row)+1,true)}</div><div class="preview-meta"><span>Editing preview · ${escape(row.set)}</span><button id="animate-art" ${work.art_frames?.length>1?'':'disabled'}>${animated?'Pause art':'Play art'}</button></div><div class="tabs" role="tablist" aria-label="Card editing sections">${['details','effects','request','advanced'].map(tab=>`<button role="tab" id="tab-${tab}" aria-controls="editor-form" aria-selected="${activeTab===tab}" tabindex="${activeTab===tab?0:-1}" data-tab="${tab}">${label(tab)}</button>`).join('')}</div><div id="editor-form" role="tabpanel" aria-labelledby="tab-${activeTab}">${activeTab==='details'?detailsForm():activeTab==='effects'?effectsForm():activeTab==='request'?`<div class="notice">Describe a new effect, artwork change, or redesign for Codex to implement.</div><label class="field">What should this card do?<textarea id="change-note" rows="7" placeholder="Example: When played, let me choose an opposing Ingredient and steal its keyword.">${escape(note)}</textarea></label><button class="primary" id="save-request">Save request for Codex</button><p class="muted" style="margin-top:14px">Then tell Codex “Implement my card change requests.” Saving a request does not change the game yet.</p>`:`<p class="muted">Complete card definition. IDs stay fixed to preserve saved decks. Unknown mechanics need a change request.</p><label class="field">Card JSON<textarea id="raw-card" class="code" spellcheck="false">${escape(JSON.stringify(work,null,2))}</textarea></label>`}</div></div><div class="editor-footer"><div class="status-row"><span id="draft-status"></span><button id="discard-draft">Reset</button></div><div class="actions"><button id="save-draft">Save draft</button><button id="review-apply" class="primary">Review & apply</button></div><div class="status-row" style="margin-top:10px"><span>Relaunch the game after applying.</span>${data.history.some(item=>item.cardId===current)?'<button id="undo-apply">Undo last apply</button>':''}</div></div>`;
  updateFooter();updateAnimation();
}
function updateFooter(){
  if(!current||!$('#save-draft'))return;
  const row=currentRow();
  $('#draft-status').textContent=rawError?'Invalid JSON':hasChanges()?'Unsaved edits':row.draft?'Draft saved':'Matches game';
  $('#save-draft').disabled=busy||!!rawError||!hasChanges();
  $('#review-apply').disabled=busy||!!rawError||same(work,row.card)||baseRevision!==row.revision;
  $('#discard-draft').disabled=busy||(!hasChanges()&&!row.draft&&!rawError);
  $('#editor').setAttribute('aria-busy',String(busy));
}
function updatePreview(){
  $('#preview-stage').innerHTML=preview(work,data.cards.indexOf(currentRow())+1,true);
  $('#editor-name').textContent=work.name||'Untitled card';updateFooter();updateAnimation();
}
function updateAnimation(){
  clearInterval(timer);const frames=work.art_frames||[];
  if(!animated||frames.length<2||matchMedia('(prefers-reduced-motion: reduce)').matches)return;
  let index=0;timer=setInterval(()=>{if(document.hidden)return;const img=$('#preview-art');if(img)img.src=assetURL(frames[++index%frames.length]);},Math.max(20,(work.art_frame_duration||.07)*1000));
}
const payload=()=>({id:current,card:work,baseRevision,draftVersion});
function diffTable(before,after){
  const keys=[...new Set([...Object.keys(before),...Object.keys(after)])].filter(key=>!same(before[key],after[key]));
  const format=value=>value===undefined?'—':typeof value==='object'?JSON.stringify(value,null,2):String(value);
  return `<table class="changes"><thead><tr><th>Field</th><th>In game</th><th>Your edit</th></tr></thead><tbody>${keys.map(key=>`<tr><th>${escape(names[key]||label(key))}</th><td>${escape(format(before[key]))}</td><td>${escape(format(after[key]))}</td></tr>`).join('')}</tbody></table>`;
}
async function reviewApply(){
  await api('/api/validate',payload());
  $('#review-title').textContent=`Apply ${work.name}`;
  $('#review-body').innerHTML=`<p>This updates the card in your local game project. A backup is saved with this change.</p>${diffTable(currentRow().card,work)}<p class="muted" style="margin-top:18px">Relaunch Godot’s running game to load the new definition. Existing exported builds need to be exported again.</p>`;
  $('#confirm-apply').textContent='Apply to game';pendingAction='apply';$('#review').showModal();
}
function clearFilters(){typeFilter='';affinityFilter='';$('#search').value='';$('#set-filter').value='';$('#art-filter').value='';$('#draft-filter').checked=false;renderFilters();renderGrid();}

document.addEventListener('click',event=>{
  if(busy){event.preventDefault();return;}
  const button=event.target.closest('button');if(!button||button.disabled)return;
  if(button.dataset.card)return selectCard(button.dataset.card);
  if(button.dataset.type){typeFilter=typeFilter===button.dataset.type?'':button.dataset.type;renderFilters();return renderGrid();}
  if(button.dataset.affinity){affinityFilter=affinityFilter===button.dataset.affinity?'':button.dataset.affinity;renderFilters();return renderGrid();}
  if(button.dataset.tab){if(rawError){toast('Fix the JSON before changing tabs.');return;}activeTab=button.dataset.tab;renderEditor();$(`#tab-${activeTab}`).focus();return;}
  if(button.dataset.addEffect){const parts=JSON.parse(button.dataset.addEffect), select=$(`#effect-${parts.join('-')}`);const list=get(parts)||[];list.push(clone(data.effectTemplates.find(effect=>effect.type===select.value)));set(parts,list);renderEditor();return;}
  if(button.dataset.removeEffect){const parts=JSON.parse(button.dataset.removeEffect);get(parts.slice(0,-1)).splice(parts.at(-1),1);renderEditor();return;}
  if(button.dataset.addOption){const parts=JSON.parse(button.dataset.addOption),effect=get(parts),key=$(`#option-${parts.join('-')}`).value,kind=data.effectSchemas[effect.type].fields[key].kind;effect[key]=kind==='boolean'?true:kind==='number'?1:kind==='array'?[]:key==='target'?'selected':key==='archetype'?'spicy':key==='card_type'?'ingredient':key==='destination'?'prep':'';renderEditor();return;}
  if(button.dataset.removeAbility!==undefined){work.abilities.splice(Number(button.dataset.removeAbility),1);renderEditor();return;}
  switch(button.id){
    case 'refresh-library':if(safeToLeave())action(async()=>{await load();toast('Library refreshed.');});break;
    case 'all-cards':case 'clear-filters':clearFilters();break;
    case 'close-editor':$('#editor').classList.remove('open');break;
    case 'animate-art':animated=!animated;button.textContent=animated?'Pause art':'Play art';updateAnimation();break;
    case 'add-trigger':{const trigger=$('#new-trigger').value;if(trigger){work[trigger]=[clone(data.effectTemplates.find(effect=>effect.type==='draw'))];renderEditor();}break;}
    case 'add-ability':work.abilities||=[];work.abilities.push({id:`${current}_ability_${crypto.randomUUID().slice(0,8)}`,timing:'activated',active_zone:work.card_type==='environment'?'environment':'plated',once_per_turn:true,effects:[{type:'draw',amount:1}]});renderEditor();break;
    case 'save-draft':action(async()=>{const result=await api('/api/draft',payload());currentRow().draft=result;draftVersion=result.version;saved=clone(work);renderGrid();toast('Draft saved. The game has not changed.');});break;
    case 'discard-draft':if(confirm('Discard this card’s draft and unsaved edits?'))action(async()=>{await api('/api/discard',{id:current,draftVersion});await load();toast('Draft discarded.');});break;
    case 'review-apply':action(reviewApply);break;
    case 'resolve-conflict':$('#review-title').textContent='Compare with current game';$('#review-body').innerHTML=`<p>The game changed after this draft began. Compare the current card with your draft below. Keeping your edit replaces the displayed fields when you apply.</p>${diffTable(currentRow().card,work)}`;$('#confirm-apply').textContent='Use current game as base';pendingAction='rebase';$('#review').showModal();break;
    case 'confirm-apply':action(async()=>{
      if(pendingAction==='rebase'){baseRevision=currentRow().revision;$('#review').close();renderEditor();toast('Compared with the current game. Review & apply when ready.');return;}
      await api(pendingAction==='undo'?'/api/undo':'/api/apply',pendingAction==='undo'?{historyId:button.dataset.historyId}:payload());$('#review').close();await load();toast(pendingAction==='undo'?'Previous card restored. Relaunch the game.':'Applied to the game. Relaunch it to load your changes.');
    });break;
    case 'undo-apply':{const record=data.history.find(item=>item.cardId===current);$('#review-title').textContent=`Undo ${record.name}`;$('#review-body').innerHTML=diffTable(currentRow().card,record.before);$('#confirm-apply').textContent='Restore previous card';$('#confirm-apply').dataset.historyId=record.id;pendingAction='undo';$('#review').showModal();break;}
    case 'save-request':action(async()=>{await api('/api/request',{id:current,note});note='';$('#change-note').value='';const fresh=await api('/api/catalog');data.requests=fresh.requests;$('#request-count').textContent=data.requests.filter(item=>item.status==='pending').length;toast('Request saved for Codex.');});break;
    case 'requests-button':$('#requests-list').innerHTML=data.requests.filter(item=>item.status==='pending').map(item=>`<article class="request-item"><h3>${escape(item.cardName)}</h3><p>${escape(item.note)}</p><span class="muted">${escape(new Date(item.createdAt).toLocaleString())}</span></article>`).join('')||'<p class="muted">No pending requests. Open a card and choose Request to write one.</p>';$('#requests').showModal();break;
    case 'copy-requests':action(async()=>{await navigator.clipboard.writeText('Implement my pending card change requests in tools/card-editor/change-requests.json. Read ART_DIRECTION.md and CONCEPT_DIRECTION.md as applicable. Update the game code, card data, and printed text to agree; validate the effects, and mark completed requests as done.\n\n'+data.requests.filter(item=>item.status==='pending').map(item=>`${item.cardName} (${item.cardId}): ${item.note}`).join('\n\n'));toast('Handoff copied. Paste it into Codex.');});break;
  }
});
document.addEventListener('input',event=>{
  if(busy)return;
  const input=event.target;
  if(input.id==='search')return renderGrid();
  if(input.id==='change-note'){note=input.value;return;}
  if(input.id==='raw-card'){
    try{const parsed=JSON.parse(input.value);if(!parsed||Array.isArray(parsed)||typeof parsed!=='object')throw new Error('Use a card object.');if(parsed.id!==current)throw new Error('Keep the card ID unchanged.');work=parsed;rawError='';notice='';$('#editor-error').hidden=true;updatePreview();}catch(error){rawError=error.message;$('#editor-error').textContent=rawError;$('#editor-error').hidden=false;updateFooter();}return;
  }
  if(input.dataset.keyword){const values=new Set(work.keywords||[]);input.checked?values.add(input.dataset.keyword):values.delete(input.dataset.keyword);work.keywords=[...values];updatePreview();return;}
  if(input.dataset.path){
    const parts=JSON.parse(input.dataset.path);let value=input.type==='checkbox'?input.checked:input.dataset.kind==='number'?Number(input.value):input.dataset.kind==='list'?input.value.split(',').map(item=>item.trim()).filter(Boolean):input.value;
    set(parts,value);notice='';$('#editor-error').hidden=true;updatePreview();
    if(parts.length===1&&parts[0]==='card_type')renderEditor();
  }
});
document.addEventListener('change',event=>{
  if(['sort','set-filter','art-filter','draft-filter'].includes(event.target.id))renderGrid();
  if(event.target.id==='upload-art')action(async()=>{
    const file=event.target.files[0];if(!file)return;
    if(file.size>12_000_000)throw new Error('Choose a PNG smaller than 12 MB.');
    const base64=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result.split(',')[1]);reader.onerror=reject;reader.readAsDataURL(file);});
    const result=await api('/api/upload',{data:base64});work.art_path=result.path;delete work.art_frames;renderEditor();toast('Artwork added to this draft. Apply the card when ready.');
  });
});
document.addEventListener('keydown',event=>{
  if(event.target.matches('[role=tab]')&&['ArrowLeft','ArrowRight','Home','End'].includes(event.key)){
    event.preventDefault();const tabs=['details','effects','request','advanced'];let index=tabs.indexOf(activeTab);index=event.key==='Home'?0:event.key==='End'?3:(index+(event.key==='ArrowRight'?1:3))%4;if(!rawError){activeTab=tabs[index];renderEditor();$(`#tab-${activeTab}`).focus();}
  }
  if((event.metaKey||event.ctrlKey)&&event.key==='s'){event.preventDefault();$('#save-draft')?.click();}
  if(event.key==='Escape'&&!$('dialog[open]'))$('#editor').classList.remove('open');
});
window.addEventListener('beforeunload',event=>{if(hasChanges()||note.trim()||rawError){event.preventDefault();event.returnValue='';}});
load().then(()=>{const first=data.cards[0];if(first)selectCard(first.card.id,true);}).catch(error=>{$('#connection').textContent='Connection unavailable';$('#card-grid').innerHTML=`<div class="empty"><h2>Could not load the cards.</h2><p>${escape(error.message)}</p><p>Keep the Card Studio launcher running, then reload this page.</p></div>`;});

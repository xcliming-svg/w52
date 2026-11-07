// RAIL//SURVIVOR static implementation-link audit. No Godot/game execution.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const here=path.dirname(new URL(import.meta.url).pathname).replace(/^\/([A-Za-z]:)/,'$1');
const read=(p)=>fs.readFileSync(path.join(here,p),'utf8');
const scriptsDir=path.join(here,'scripts');
const gdFiles=fs.readdirSync(scriptsDir).filter(f=>f.endsWith('.gd'));
const files=Object.fromEntries(gdFiles.map(f=>[f,read('scripts/'+f)]));
const project=read('project.godot'),exportCfg=read('export_presets.cfg');
const contract=read('../docs/CONTRACT.md');
const manifest=JSON.parse(read('../docs/IMPLEMENTATION_MANIFEST.json'));
const nodes=JSON.parse(read('tree_nodes.json')).nodes;
const contains=(file,...tokens)=>{
 assert.ok(Object.hasOwn(files,file),file+' is missing');
 for(const token of tokens)assert.ok(files[file].includes(token),file+' missing '+token);
};
const pathRef=(p)=>assert.ok(fs.existsSync(path.resolve(here,p)),p+' missing');

assert.equal(Object.values(manifest.tasks).length,179);
assert.match(project,/run\/main_scene="res:\/\/main.tscn"/);
assert.match(project,/physics_ticks_per_second=60/);
assert.match(project,/rendering_method="gl_compatibility"/);
assert.match(exportCfg,/platform="Windows Desktop"/);
assert.match(exportCfg,/binary_format\/architecture="x86_64"/);
assert.match(exportCfg,/platform="Web"/);
assert.match(exportCfg,/variant\/thread_support=false/);
assert.ok(contract.includes('W10'));

contains('run_controller.gd','field.step','train.step','weapons.step','economy.step','autosave.when_due','RRecords.submit','RFixedTickRunner.tick_count','RFrameBudget.effective_speed');
contains('app.gd','_open_run','_show_menu','_show_settings','_show_records','_exit_application','RStateMachine.new');
contains('rail_path.gd','1175.0','1950.0','3125.0','RAIL_SPACING');
contains('balance_config.gd','MAX_TRAIN: int = 50','TREE_NODES: int = 121','HULL_MAX: float = 250','BARRIER_MAX: float = 30');
contains('train_controller.gd','RCoachFormation.position','RWagonShop.buy','RTrainStorage.synchronize','RCoachOrder.swap','RTrainRepair.repair_car','RHullDamage');
contains('enemy_system.gd','REnemyFactory.create','RSpawnDirector.accrue','RAiRunner.steering','RAiArtillery','RAiSuicide','RBossController.tick','REnemyContact.hit_if_overlapping','RStatusDot.tick','RHitEventDedup.accept','RDefenseResists.mitigate','enemy_killed.emit','battlefield_loss.emit','_step_hazards');
contains('weapon_system.gd','RTargetSelector.best','RDamagePipeline.resolve','RStatusChain.next_target','RHitGeometry.segment_distance','spatial.rebuild','pool.acquire');
contains('projectile_system.gd','query_segment','RHitGeometry.segment_distance','system._explode','field.slow_enemy','system.pool.recycle');
contains('economy.gd','RTimePoints.accrue','RXpRewards.kill','RScrapRewards.kill','RUpgradePricing.quote','RWagonPricing.quote','record_once','transaction_serial += 1','RECENT_KILL_WINDOW');
contains('enemy_contact.gd','RHitGeometry.intersects_circle','RRailPath.nearest_rail_position','COOLDOWN_SECONDS');
contains('tree_refund.gd','refund:','transaction_id');
contains('tree_purchase_transaction.gd','last_transaction_id');
contains('save_store.gd','BACKUP_A','BACKUP_B','RSaveSchema.valid','RSaveMigration.migrate','_atomic_write','_read');
contains('save_schema.gd','hostile_projectiles','is_finite(float(enemy.pos[0]))');
contains('game_rng.gd','gameplay.state','visuals.state','"gameplay_state":str(gameplay.state)');
contains('tree_rules.gd','RTreePurchaseTransaction.commit','RTreeRefund.cancel','RTreeReset.execute','has_milestone("W",10)');
contains('visual_effects.gd','RDamageNumbers.accept','RDebrisPhysics.step','RDebrisSplit.scatter','RRenderBatch.draw_many_rects','overflow_damage_log');
contains('audio_router.gd','RAudioPolyphony','RSfxGenerator.tone','RMusicManager','RBrowserAudio');
contains('run_controller.gd','RCleanupLifecycle.clear_run(self)','labels_unchanged');
contains('battlefield.gd','RViewportAdapter.fit_world','RRailRenderer.paint','RPortalRenderer.paint','RCornerIndicators.paint','RAccessibility.translate_color');
const families=['pistol','gatling','shotgun','sniper','mortar','rocket','blade','flame','frost','tesla','support','shockwave'];
for(const family of families){
 pathRef('scripts/gun_'+family+'.gd');
 assert.ok(files['weapon_system.gd'].includes('GUN_'+family.toUpperCase()+'.fire('),'missing dispatch '+family);
}
const stitched=gdFiles.map(name=>files[name]).join('\n');
const milestones=nodes.filter(node=>node.milestone);
assert.equal(milestones.length,36);
for(const node of milestones){
 const rx=new RegExp('has_milestone\\("'+node.branch+'"\\s*,\\s*'+node.depth+'\\)');
 assert.ok(rx.test(stitched),node.milestone.effectId+' missing effect guard');
}
const classes=new Map();
for(const [name,body] of Object.entries(files)){
 const match=body.match(/^class_name\s+(\w+)/m);
 if(!match)continue;
 assert.ok(!classes.has(match[1]),'duplicate class_name '+match[1]);
 classes.set(match[1],name);
}
for(const [className,original] of classes){
 if(className==='RApp'){
  assert.ok(read('main.tscn').includes('res://scripts/app.gd'));
  continue;
 }
 const inbound=gdFiles.some(file=>file!==original && new RegExp('\\b'+className+'\\b').test(files[file]));
 assert.ok(inbound,original+' unlinked global class '+className);
}
for(const task of Object.values(manifest.tasks)){
 let target=task.sourcePath;
 if(target.startsWith('src/'))target=target.slice(4);
 if(target.startsWith('docs/'))target='../'+target;
 if(target.startsWith('../.github/'))target='../'+target.replace(/^\.\.\//,'../');
 pathRef(target);
}
const font=path.join(here,'assets','NotoSansKR-Regular.ttf');
const fontLicense=path.join(here,'assets','NotoSansKR-LICENSE.txt');
const isFontBundled=fs.existsSync(font)&&fs.existsSync(fontLicense);
console.log('STATIC_CONTRACT_LINKS_PASS: 179 paths; 36 effect guards; 12 weapon dispatches; '+classes.size+' linked classes.');
if(!isFontBundled){
 console.warn('BLOCKED_P11-06: Korean web font and license have not been bundled. This is not a release-ready project.');
}
console.log('RUNTIME_UNVERIFIED: Godot execution, WebGL2 export, Windows x86_64 export, Steam release, 3h/performance QA were not run.');

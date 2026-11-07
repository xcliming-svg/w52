// Non-runtime static data/contract validation. No Godot engine invocation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const here = path.dirname(new URL(import.meta.url).pathname);
const root = process.platform === 'win32' && /^\/[A-Za-z]:/.test(here) ? here.slice(1) : here;
const json = name => JSON.parse(fs.readFileSync(path.join(root,name),'utf8'));
const tree=json('tree_nodes.json'), wagons=json('wagons.json'), enemies=json('enemies.json');
const manifest=json('../docs/IMPLEMENTATION_MANIFEST.json');
const tasks=Object.values(manifest.tasks);
assert.equal(tasks.length,179,'Manifest requires 179 individual tasks');
assert.equal(tasks.filter(t=>t.required).length,179,'All tasks required');
assert.equal(new Set(tasks.map(t=>t.id)).size,179,'Manifest IDs must be unique');
for(const [name,list,length] of [['nodes',tree.nodes,121],['cars',wagons.cars,36],['enemies',enemies.enemies,14]]){
  assert.equal(list.length,length,name+' count');
  assert.equal(new Set(list.map(e=>e.id)).size,length,name+' IDs');
}
assert.equal(tree.nodes.filter(n=>n.id==='C000').length,1);
assert.equal(tree.branchOrder.length,12);
for(const id of tree.branchOrder.map(b=>b.id)){
  const row=tree.nodes.filter(n=>n.branch===id);
  assert.equal(row.length,10,id+' branch depth count');
  assert.deepEqual(row.map(n=>n.depth).sort((a,b)=>a-b),[1,2,3,4,5,6,7,8,9,10]);
}
const nodeById=new Map(tree.nodes.map(n=>[n.id,n]));
for(const row of tree.nodes) for(const prev of row.requires||[]){
  assert.ok(nodeById.has(prev),row.id+' missing dependency '+prev);
  assert.ok((nodeById.get(prev).depth||0)<row.depth,row.id+' depends on non-prior depth');
}
assert.equal(tree.nodes.filter(n=>n.milestone).length,36);
assert.equal(new Set(tree.nodes.filter(n=>n.milestone).map(n=>n.milestone.effectId)).size,36);
for(let k=1;k<=10;k++)assert.equal(nodeById.get('W'+String(k).padStart(2,'0')).value,k===10?4:5);
const families=new Set(['pistol','gatling','shotgun','sniper','mortar','rocket','blade','flame','frost','tesla','support','shockwave']);
assert.deepEqual(new Set(wagons.cars.map(c=>c.family)),families);
for(const f of families)assert.deepEqual(wagons.cars.filter(w=>w.family===f).map(w=>w.tier).sort(),[1,2,3]);
for(const w of wagons.cars)assert.equal(w.shape,'rectangle');
for(const e of enemies.enemies){
  assert.equal(e.canEscape,true);
  assert.ok(e.escapeDamage>=0.5&&e.escapeDamage<=3);
  assert.ok(e.hullDamage>=0);
  assert.ok([1,4,15].includes(e.rewardMultiplier));
}
const counts=Object.fromEntries(manifest.groups.map(g=>[g.id,0]));
for(const t of tasks){assert.ok(Object.hasOwn(counts,t.phase));counts[t.phase]++;}
for(const g of manifest.groups)assert.equal(counts[g.id],g.requiredCount,g.id+' phase count');
console.log('STATIC_DATA_PASS 179 manifest IDs, 121 nodes/36 milestones, 36 wagons, 14 enemies, formulas and references');

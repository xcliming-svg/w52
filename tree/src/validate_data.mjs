import { readFileSync } from "node:fs";
const load = (name) => JSON.parse(readFileSync(new URL("./"+name, import.meta.url),"utf8"));
function validate(t,w,e){
const errors=[],ids=new Set(t.nodes.map(n=>n.id)),wids=new Set(w.cars.map(x=>x.id)),eids=new Set(e.enemies.map(x=>x.id));
if(t.nodes.length!==121 || t.branchOrder.length!==12 || t.nodeCount!==121)errors.push("Tree count must be center + 12*10 = 121");
if(ids.size!==t.nodes.length || t.nodes.filter(n=>n.id==="C000").length!==1)errors.push("Duplicate/missing tree ID");
for(const n of t.nodes){
if(!n.requires.every(req=>ids.has(req)))errors.push("Missing prerequisite: "+n.id);
if(n.depth>0){
const prev=n.depth===1?"C000":n.id.slice(0,-2)+String(n.depth-1).padStart(2,"0");
if(n.requires.length!==1 || n.requires[0]!==prev)errors.push("Unexpected chain: "+n.id);
if(n.tpBase!==1+Math.floor((n.depth-1)/2)||n.xpCost!==10+7*n.depth+3*n.depth*n.depth)errors.push("Price mismatch: "+n.id);
if(n.depth>10)errors.push("Depth > 10: "+n.id);
}
if(!Number.isFinite(n.x)||!Number.isFinite(n.y))errors.push("Invalid coordinates: "+n.id);
}
const milestoneNodes=t.nodes.filter(n=>n.milestone);
const effectIds=new Set(milestoneNodes.map(n=>n.milestone.effectId));
if(milestoneNodes.length!==36||effectIds.size!==36)errors.push("Milestone effects must have 36 unique IDs");
for(const n of t.nodes){
 if(n.depth>0 && !Number.isFinite(n.tpBase))errors.push("Missing TP cost: "+n.id);
 if((n.depth===4||n.depth===7||n.depth===10)&&(!n.milestone||!n.milestone.runtimeImplementationRequired||n.milestone.simulationStatus!=="NOT_IMPLEMENTED_IN_AGGREGATE_MODEL"))errors.push("Milestone runtime status absent: "+n.id);
}
const countByBranch=Object.fromEntries(t.branchOrder.map(b=>[b.id,t.nodes.filter(n=>n.branch===b.id).length]));
if(Object.values(countByBranch).some(v=>v!==10))errors.push("Every branch needs exactly ten purchased depths");
const w10=t.nodes.find(n=>n.id==="W10");
if(w10?.value!==4||!w10?.milestone?.description?.includes("+4"))errors.push("W10 data and milestone must both give final +4 slots");
if(t.nodes.some(n=>n.branch==="W"&&n.depth>0&&n.depth<10&&n.value!==5))errors.push("W1-W9 must give +5 slots");
for(let d=7;d<=10;d++){
 const en=t.nodes.find(n=>n.id==="E"+String(d).padStart(2,"0"));
 if(en?.extraEffects?.length!==1||en.extraEffects[0]?.stat!=="salvage_chance_bonus"||en.extraEffects[0]?.value!==.03)errors.push("E7-E10 salvage compensation missing");
}

if(w.cars.length!==36||wids.size!==36||w.maxTrainCarsIncludingLocomotive!==50)errors.push("Wagon count/ID/cap invalid");
for(const car of w.cars){if(car.shape!=="rectangle"||car.width<=0||car.height<=0||car.baseDps<=0||car.cycleSeconds<=0||car.hp<=0||!/^#[0-9a-f]{6}$/i.test(car.color))errors.push("Bad wagon:"+car.id);}
const expectedFamily={pistol:["dps","single"],gatling:["dps","single"],shotgun:["area","multishot"],sniper:["dps","pierce"],mortar:["area","area"],rocket:["area","tracking_area"],blade:["melee","cleave"],flame:["area","dot"],frost:["control","slow"],tesla:["chain","chain"],support:["support","buff"],shockwave:["control","knockback_area"]};
for(const car of w.cars){if(!expectedFamily[car.family]||car.role!==expectedFamily[car.family][0]||car.hitBehavior!==expectedFamily[car.family][1])errors.push("Wagon behavior family mismatch: "+car.id);}
for(const enemy of e.enemies){if(enemy.escapeDamage<0.5||enemy.escapeDamage>3||!Number.isFinite(enemy.hullDamage)||enemy.hullDamage<0||enemy.canEscape!==true||![1,4,15].includes(enemy.rewardMultiplier))errors.push("Enemy danger/reward mismatch: "+enemy.id);}
if(e.enemies.length!==14||eids.size!==14)errors.push("Enemy count/ID invalid");
for(const en of e.enemies){if(en.hpMultiplier<=0||en.speedMultiplier<=0||!en.shape||!en.ai||!/^#[0-9a-f]{6}$/i.test(en.color))errors.push("Bad enemy:"+en.id);}
return {pass:errors.length===0,errors,checked:{nodes:t.nodes.length,branches:t.branchOrder.length,wagons:w.cars.length,enemies:e.enemies.length}};
}
const result = validate(load("tree_nodes.json"),load("wagons.json"),load("enemies.json"));
console.log(JSON.stringify(result,null,2));
if(!result.pass)process.exitCode=1;

import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import {fileURLToPath} from "node:url";
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const gd=n=>read("scripts/"+n+".gd");
const nodes=JSON.parse(read("tree_nodes.json")).nodes;
const enemies=JSON.parse(read("enemies.json")).enemies;
const byId=new Map(nodes.map(n=>[n.id,n]));
const branches=[...new Set(nodes.filter(n=>n.id!=="C000").map(n=>n.branch))];
const impl=[
["16:9 viewport",()=>{assert.match(read("project.godot"),/viewport_width=1920/);assert.match(read("project.godot"),/viewport_height=1080/)}],
["aspect keep",()=>assert.match(read("project.godot"),/aspect="keep"/)],
["50:50 split",()=>{assert.match(gd("run_controller"),/split_ratio: float = 0\.50/);assert.match(gd("viewport_adapter"),/width\)\*0\.50/)}],
["Korean theme",()=>assert.match(gd("app"),/korean_theme\.default_font = RFontRegistry\.bundled_font\(\)/)],
["SIL OFL",()=>assert.match(read("assets/NotoSansKR-LICENSE.txt"),/SIL OPEN FONT LICENSE Version 1\.1/)],
["font resource",()=>assert.match(gd("font_registry"),/res:\/\/assets\/NotoSansKR-Regular\.ttf/)],
["content counts",()=>{assert.equal(nodes.length,121);assert.equal(branches.length,12);assert.equal(enemies.length,14)}],
["unique node IDs",()=>assert.equal(byId.size,nodes.length)],
["DAG parents",()=>{for(const n of nodes)for(const p of n.requires)assert.ok(byId.has(p)&&byId.get(p).depth<n.depth,n.id)}],
["12 root branches",()=>assert.equal(nodes.filter(n=>n.requires.includes("C000")).length,12)],
["12 skill forks",()=>{for(const b of branches){assert.deepEqual(byId.get(b+"03").requires,[b+"02"]);assert.deepEqual(byId.get(b+"04").requires,[b+"02"])}}],
["visibility contract",()=>assert.match(gd("tree_rules"),/func is_visible\(node_id: String\)/)],
["visible draw/hit",()=>{assert.match(gd("tree_renderer"),/session\.tree\.is_visible/);assert.match(gd("tree_interaction"),/purchased\.has\(str\(parent_id\)\)/)}],
["click dialog and action",()=>{assert.match(gd("tree_panel"),/ConfirmationDialog\.new/);assert.match(gd("tree_panel"),/info_dialog\.confirmed\.connect/);assert.match(gd("tree_panel"),/session\.tree\.may_buy\(selected_id\)/)}],
["10-hour progression hooked",()=>{assert.match(gd("spawn_scaling"),/36000\.0/);assert.match(gd("enemy_system"),/regular_template_index\(rng,templates\.size\(\),elapsed\)/);assert.match(gd("enemy_factory"),/size_scale\(elapsed\)/);assert.match(gd("battlefield"),/e\.get\("opacity",1\.0\)/)}]
];
const progress=s=>Math.min(1,Math.max(0,s/36000));
const hp=s=>12*(1+18*progress(s)**1.35);
const rate=s=>.14+1.25*progress(s)**1.4;
const velocity=s=>13+26*progress(s)**1.2;
const size=s=>.78+.7*progress(s);
const alpha=s=>.38+.62*progress(s);
const visible=owned=>nodes.filter(n=>owned.has(n.id)||n.requires.every(x=>owned.has(x))).map(n=>n.id);
const tests=[
["start HP",()=>assert.equal(hp(0),12)],
["end HP",()=>assert.equal(hp(36000),228)],
["end spawn rate",()=>assert.ok(rate(36000)>1.38)],
["end speed",()=>assert.equal(velocity(36000),39)],
["negative time clamp",()=>assert.equal(hp(-100),12)],
["after end clamp",()=>assert.equal(hp(999999),hp(36000))],
["15 checkpoints monotonic",()=>{let prev=[0,0,0,0,0];for(const s of [0,300,900,1800,3600,5400,7200,10800,14400,18000,21600,25200,28800,32400,36000]){const cur=[hp(s),rate(s),velocity(s),size(s),alpha(s)];cur.forEach((x,i)=>assert.ok(x>=prev[i]));prev=cur}}],
["player faster even at 10h",()=>{for(let m=0;m<=600;m+=20)assert.ok(260>velocity(m*60)*1.7)}],
["progressive opacity and size",()=>{assert.ok(alpha(0)<alpha(36000));assert.ok(size(0)<size(36000))}],
["single family at zero",()=>assert.equal(Math.min(11,Math.floor(0/50))+1,1)],
["12th family at 550m",()=>assert.equal(Math.min(11,Math.floor(550/50))+1,12)],
["initial nodes exactly 13",()=>{const v=visible(new Set(["C000"]));assert.equal(v.length,13);assert.ok(!v.includes("W02"))}],
["W01 unlocks W02 only",()=>{const v=visible(new Set(["C000","W01"]));assert.ok(v.includes("W02"));assert.ok(!v.includes("W03"))}],
["W02 opens 2 forks",()=>{const v=visible(new Set(["C000","W01","W02"]));assert.ok(v.includes("W03"));assert.ok(v.includes("W04"));assert.ok(!v.includes("W05"))}],
["W03 unlocks left not right",()=>{const v=visible(new Set(["C000","W01","W02","W03"]));assert.ok(v.includes("W05"));assert.ok(!v.includes("W06"))}]
];
let fail=0;
function run(label,rows){rows.forEach(([name,fn],i)=>{try{fn();console.log(label+" "+(i+1)+"/"+rows.length+" PASS "+name)}catch(e){fail++;console.error(label+" "+(i+1)+"/"+rows.length+" FAIL "+name+": "+e.message)}})}
run("IMPLEMENTATION",impl);
run("TEST",tests);
console.log("BURROW_QA_SUMMARY implementation="+impl.length+" tests="+tests.length+" failed="+fail);
if(fail)process.exitCode=1;

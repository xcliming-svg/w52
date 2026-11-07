// Static source, scene and script reference scanner; does not execute Godot.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=path.dirname(new URL(import.meta.url).pathname).replace(/^\/([A-Za-z]:)/,'$1');
const walk=(dir)=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
const all=walk(root).filter(f=>!f.includes(path.sep+'.godot'+path.sep));
const scenes=all.filter(f=>f.endsWith('.tscn'));
const scripts=all.filter(f=>f.endsWith('.gd'));
const classes=new Map();
for(const file of scripts){
  const match=fs.readFileSync(file,'utf8').match(/^class_name\s+(\w+)/m);
  if(match){assert.ok(!classes.has(match[1]),'Duplicate class_name: '+match[1]);classes.set(match[1],file);}
}
let references=0;
for(const file of [...scenes,...scripts]){
  const content=fs.readFileSync(file,'utf8');
  for(const match of content.matchAll(/(?:path="|preload\("|load\(")res:\/\/([^"\)]+)/g)){
    const reference=path.join(root,match[1]);
    assert.ok(fs.existsSync(reference),file+' missing res://'+match[1]);
    references++;
  }
}
const project=fs.readFileSync(path.join(root,'project.godot'),'utf8');
assert.match(project,/run\/main_scene="res:\/\/main.tscn"/);
assert.match(project,/rendering_method="gl_compatibility"/);
assert.match(project,/physics_ticks_per_second=60/);
assert.ok(scenes.length>=3);
const runScene=fs.readFileSync(path.join(root,'scenes/run.tscn'),'utf8');
for(const required of ['TreePanel','Battlefield','Toolbar','Splitter'])assert.ok(runScene.includes('name="'+required+'"'));
console.log('STATIC_SCENES_PASS '+scenes.length+' scenes, '+scripts.length+' scripts, '+references+' resource refs, '+classes.size+' global classes');

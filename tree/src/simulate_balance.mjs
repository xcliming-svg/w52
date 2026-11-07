// tree / reproducible aggregate balance MODEL; NOT gameplay or actual playtest

const PROFILES = {
  "balanced": [
    1.3,
    1.5,
    1.4,
    1,
    1.1,
    1,
    1.05,
    0.9,
    0.8,
    0.85,
    0.8,
    0.8
  ],
  "artillery": [
    1.1,
    1.9,
    1.7,
    1.3,
    1.4,
    1.2,
    0.25,
    0.4,
    0.3,
    0.5,
    1,
    0.9
  ],
  "armored": [
    0.95,
    0.95,
    0.9,
    0.75,
    0.8,
    0.85,
    2,
    0.9,
    1.4,
    0.8,
    0.4,
    0.4
  ],
  "economist": [
    1.25,
    1.2,
    1.25,
    0.9,
    1,
    0.8,
    0.65,
    2,
    0.6,
    0.7,
    0.8,
    0.8
  ],
  "optimizer": [
    2.05,
    1.82,
    1.68,
    1.3,
    1.2,
    0.8,
    0.45,
    0.78,
    0.5,
    0.55,
    1.04,
    0.9
  ]
};

const VARIANTS = [
  {
    "tag": "R1",
    "tp": 0.027,
    "scrap": 0.05,
    "xp": 0.85,
    "enemy": 1.07,
    "hp": 1.1,
    "hpExp": 1.78,
    "spawnExp": 1.29,
    "window": 15,
    "upgrade": 0.085,
    "glob": 14,
    "combo": 0
  },
  {
    "tag": "R2",
    "tp": 0.029,
    "scrap": 0.07,
    "xp": 0.95,
    "enemy": 1.02,
    "hp": 1.06,
    "hpExp": 1.76,
    "spawnExp": 1.27,
    "window": 16,
    "upgrade": 0.091,
    "glob": 16,
    "combo": 0
  },
  {
    "tag": "R3",
    "tp": 0.031,
    "scrap": 0.084,
    "xp": 1,
    "enemy": 1,
    "hp": 1.03,
    "hpExp": 1.74,
    "spawnExp": 1.25,
    "window": 17,
    "upgrade": 0.096,
    "glob": 17,
    "combo": 0
  },
  {
    "tag": "R4",
    "tp": 0.033,
    "scrap": 0.099,
    "xp": 1.02,
    "enemy": 1,
    "hp": 1,
    "hpExp": 1.72,
    "spawnExp": 1.25,
    "window": 18,
    "upgrade": 0.1,
    "glob": 18,
    "combo": 0
  },
  {
    "tag": "R5",
    "tp": 0.033,
    "scrap": 0.108,
    "xp": 1.04,
    "enemy": 1.01,
    "hp": 1,
    "hpExp": 1.72,
    "spawnExp": 1.25,
    "window": 18,
    "upgrade": 0.103,
    "glob": 19,
    "combo": 0
  },
  {
    "tag": "R6",
    "tp": 0.0335,
    "scrap": 0.112,
    "xp": 1.05,
    "enemy": 1.02,
    "hp": 1.01,
    "hpExp": 1.72,
    "spawnExp": 1.26,
    "window": 18.5,
    "upgrade": 0.104,
    "glob": 20,
    "combo": 0
  },
  {
    "tag": "R7",
    "tp": 0.0335,
    "scrap": 0.112,
    "xp": 1.05,
    "enemy": 1.02,
    "hp": 1.01,
    "hpExp": 1.72,
    "spawnExp": 1.26,
    "window": 18.5,
    "upgrade": 0.104,
    "glob": 20,
    "combo": 0.038
  },
  {
    "tag": "R8",
    "tp": 0.0335,
    "scrap": 0.109,
    "xp": 1.05,
    "enemy": 1.03,
    "hp": 1.02,
    "hpExp": 1.72,
    "spawnExp": 1.26,
    "window": 18.5,
    "upgrade": 0.104,
    "glob": 20,
    "combo": 0.047
  },
  {
    "tag": "R9",
    "tp": 0.0335,
    "scrap": 0.109,
    "xp": 1.05,
    "enemy": 1.03,
    "hp": 1.02,
    "hpExp": 1.72,
    "spawnExp": 1.26,
    "window": 18.5,
    "upgrade": 0.104,
    "glob": 20,
    "combo": 0.054
  },
  {
    "tag": "R10",
    "tp": 0.0335,
    "scrap": 0.109,
    "xp": 1.05,
    "enemy": 1.03,
    "hp": 1.02,
    "hpExp": 1.72,
    "spawnExp": 1.26,
    "window": 18.5,
    "upgrade": 0.104,
    "glob": 20,
    "combo": 0.061
  },
{
  "tag": "R11",
  "tp": 0.0335,
  "scrap": 0.109,
  "xp": 1.05,
  "enemy": 1.03,
  "hp": 1.02,
  "hpExp": 1.72,
  "spawnExp": 1.26,
  "window": 18.5,
  "upgrade": 0.104,
  "glob": 20,
  "combo": 0.065,
  "comboCap": 1.75
},
{
  "tag": "R12",
  "tp": 0.0335,
  "scrap": 0.109,
  "xp": 1.05,
  "enemy": 1.01,
  "hp": 1.02,
  "hpExp": 1.72,
  "spawnExp": 1.25,
  "window": 18.5,
  "upgrade": 0.104,
  "glob": 20,
  "combo": 0.07,
  "comboCap": 1.62
},
{
  "tag": "R13",
  "tp": 0.0335,
  "scrap": 0.109,
  "xp": 1.05,
  "enemy": 1.02,
  "hp": 1.02,
  "hpExp": 1.7,
  "spawnExp": 1.26,
  "window": 18.5,
  "upgrade": 0.104,
  "glob": 20,
  "combo": 0.06,
  "comboCap": 1.75
},
{
  "tag": "R14",
  "tp": 0.0335,
  "scrap": 0.109,
  "xp": 1.05,
  "enemy": 1.02,
  "hp": 1.02,
  "hpExp": 1.71,
  "spawnExp": 1.255,
  "window": 18.5,
  "upgrade": 0.104,
  "glob": 20,
  "combo": 0.067,
  "comboCap": 1.72
}
];

function simulate(c,profile,seed){
let prng=(function(x){return()=>{x^=x<<13;x^=x>>>17;x^=x<<5;return (x>>>0)/4294967296}})(seed);
let level=Array(12).fill(0),tp=0,xp=0,scrap=0,barrier=30,queue=0,wagons=1,nodes=0,kills=0,leaks=0,finish=180,snapshots={};
let waveTrait=.86+.28*prng(),rewardTrait=.9+.2*prng();
for(let t=0;t<10800;t+=5){
let minute=t/60;
tp+=5*c.tp*(1+.03*level[7]);
for(let purchase=0;purchase<2;purchase++){
let best=-1,score=0;
for(let i=0;i<12;i++){
 let depth=level[i]+1;if(depth>10)continue;
 let tpCost=1+Math.floor((depth-1)/2)+Math.floor(nodes/c.glob);
 let xpCost=10+7*depth+3*depth*depth;
 if(tp<tpCost||xp<xpCost)continue;
 let weight=PROFILES[profile][i]/(1+.10*(depth-1));
 if(i===0&&wagons>=1+5*level[0])weight*=2.8;
 if(i===6&&barrier<15)weight*=2;
 if(i===1&&queue>10)weight*=1.35;
 if(weight>score){best=i;score=weight;}
}
if(best<0)break;
let depth=++level[best];
tp-=1+Math.floor((depth-1)/2)+Math.floor(nodes/c.glob);
xp-=10+7*depth+3*depth*depth;nodes++;
}
let capacity=Math.min(50,1+5*level[0]);
for(let j=0;j<2&&wagons<capacity;j++){let cost=11+2.3*(wagons-1);if(scrap>=cost){scrap-=cost;wagons++;}}
let pulse=Math.floor(minute)%10===9&&t%600<40?1.42:1;
let spawnRate=c.enemy*waveTrait*.85*Math.pow(1+minute/12,c.spawnExp)*pulse*(.92+.16*prng());
let hp=18*c.hp*Math.pow(1+minute/20,c.hpExp)*(minute>=30?1.14:1);
let dps=(30+20*(wagons-1))*(1+c.upgrade*level[1])*(1+.09*level[2])*(1+.065*level[3])*(1+.065*level[10])*(1+.028*(level[4]+level[5]+level[11]));
dps*=Math.min(c.comboCap ?? 1e9, 1+c.combo*Math.max(0,wagons-24)*(1+.08*level[2]));
let coverage=Math.min(1.14,.68+.025*level[9]+.019*level[4]+.015*level[8]);
queue+=spawnRate*5;
let dead=Math.min(queue,dps*coverage*5/(hp*1.17));
queue-=dead;
let limit=spawnRate*(c.window+level[8]*.65);
let escaped=Math.max(0,queue-limit)*.32;
queue-=escaped;leaks+=escaped;
barrier-=escaped/(1+.035*level[6]);
kills+=dead;
xp+=dead*c.xp*rewardTrait*(1+.04*level[7]);scrap+=dead*c.scrap*rewardTrait*(1+.045*level[7]);
if(t===600||t===1800||t===3600||t===7200) snapshots[t/60]={wagons,nodes,leaks:Math.round(leaks)};
if(barrier<=0){finish=Math.round(t/6)/10;break;}
}
return {minutes:finish,wagons,nodes,kills:Math.round(kills),leaks:Math.round(leaks),snapshots};
}

function measure(){
let summary={};
for(let c of VARIANTS){summary[c.tag]={};
for(let p of Object.keys(PROFILES)){
let arr=Array.from({length:32},(_,i)=>simulate(c,p,751+i*37)).sort((a,b)=>a.minutes-b.minutes);
summary[c.tag][p]={p10:arr[3].minutes,p50:arr[16].minutes,p90:arr[28].minutes,above120:arr.filter(a=>a.minutes>=120).length,atCap:arr.filter(a=>a.minutes>=180).length,wagons:arr[16].wagons,nodes:arr[16].nodes};}
}
return summary;
}

console.log(JSON.stringify(measure(), null, 2));

// Standalone 1-second cohort model; diagnostics, not a Godot gameplay runtime.
// Previous 5-second aggregate experiments remain in simulate_balance.mjs.
// R15-CANDIDATE: empirical proxy calibration, NOT a proven Godot combat multiplier.
// Previous R14 aggregate values are historical, not a validation baseline.
const BRANCHES = ["W","R","S","H","C","X","A","E","F","L","U","P"];
const PROFILES = {
  balanced:  { weights:[1.30,1.50,1.40,1,1.10,1,1.05,.90,.80,.85,.80,.80], coachFactor:1.00, leakFactor:1.00 },
  artillery: { weights:[1.10,1.90,1.70,1.30,1.40,1.20,.25,.40,.30,.50,1,.90], coachFactor:1.05, leakFactor:1.04 },
  armored:   { weights:[.95,.95,.90,.75,.80,.85,2,.90,1.40,.80,.40,.40], coachFactor:1.03, leakFactor:.83 },
  economist: { weights:[1.25,1.20,1.25,.90,1,.80,.65,2,.60,.70,.80,.80], coachFactor:1.00, leakFactor:1.03 },
  optimizer: { weights:[2.05,1.82,1.68,1.30,1.20,.80,.45,.78,.50,.55,1.04,.90], coachFactor:1.06, leakFactor:1.00 }
};
const BASE = {tp:.0335, xp:1.05, scrap:.109, enemy:1.02, hp:1.02, hpExp:1.71, spawnExp:1.255, upgrade:.104, synergy:.067, synergyCap:1.72, damageScale:1.25, timeStep:1, maxMinutes:180, railLength:3900, wagonGap:28, engineSpeed:220, openingRangeSeconds:7};
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function seeded(seed){let x=seed|0;return ()=>{x^=x<<13;x^=x>>>17;x^=x<<5;return (x>>>0)/4294967296;};}
function slotCapacity(tier){return clamp(1+Math.max(0,Math.min(9,tier))*5+Math.max(0,tier-9)*4,1,50);}
function coverage(lv){return clamp(.68+.025*lv[9]+.019*lv[4]+.015*lv[8],0,1);}
function econRates(tier){return {tp:1+Math.min(.24,.03*tier),xp:1+Math.min(.28,.04*tier),scrap:1+Math.min(.30,.045*tier)};}
function nodeCost(depth,alreadyBought){return {tp:1+Math.floor((depth-1)/2)+Math.floor(alreadyBought/20), xp:10+7*depth+3*depth*depth};}
function attemptBuy(state, branchIndex, allowRefund=false){
  const depth=state.levels[branchIndex]+1; if(depth>10)return false;
  const price=nodeCost(depth,state.nodes);
  if(state.tp+1e-10<price.tp||state.xp+1e-10<price.xp)return false;
  state.tp-=price.tp; state.xp-=price.xp; state.levels[branchIndex]++; state.nodes++;
  if(allowRefund)state.purchases.push({branchIndex,depth,price,gameTime:state.time,rewardCounter:state.rewardCounter});
  return true;
}
function makeState(){return {levels:Array(12).fill(0),nodes:0,tp:0,xp:20,scrap:0,wagons:1,barrier:30,time:0,purchases:[],trainHP:250,rewardCounter:0};}
// Event-system design contract: an enemy may pay its kill reward only once.
function creditUniqueKill(state,enemy,xp,scrap){
 if(enemy.rewarded || enemy.hp>0 || !Number.isFinite(xp) || !Number.isFinite(scrap) || xp<0 || scrap<0)return false;
 enemy.rewarded=true;state.xp+=xp;state.scrap+=scrap;state.rewardCounter++;return true;
}

function refundRecent(state, minTime=0){
 const last=state.purchases.at(-1);
 // No refund after a simulation tick: otherwise an upgrade can affect combat or rewards for free.
 if(!last || last.depth>3 || state.time!==last.gameTime || state.time<minTime || last.refunded || last.rewardCounter!==state.rewardCounter)return false;
 if(state.levels[last.branchIndex]!==1+state.purchases.slice(0,-1).filter(x=>x.branchIndex===last.branchIndex && !x.refunded).length)return false;
 state.tp+=last.price.tp;state.xp+=last.price.xp;state.nodes--;state.levels[last.branchIndex]--;
 last.refunded=true;state.purchases.pop();return true;
}
function chooseBuy(state,profile,backlog){
  let best=-1,weight=-1;
  for(let i=0;i<12;i++){
    const d=state.levels[i]+1;if(d>10)continue;
    const cost=nodeCost(d,state.nodes);
    if(state.tp+1e-10<cost.tp||state.xp+1e-10<cost.xp)continue;
    let score=profile.weights[i]/(1+.10*(d-1));
    if(i===0 && state.wagons>=slotCapacity(state.levels[i]))score*=2.8;
    if(i===6 && state.barrier<=14)score*=2.0;
    if(i===1 && backlog>15)score*=1.35;
    if(score>weight){weight=score;best=i;}
  }
  return best;
}
function wagonDps(state,profile,c){
 const lv=state.levels;
 // Class-factor proxy only. Individual 36-car weapons, travel and projectiles remain unmodeled.
 const raw=(30+20*(state.wagons-1)*profile.coachFactor);
 const multi=(1+c.upgrade*lv[1])*(1+.09*lv[2])*(1+.065*lv[3])*(1+.065*lv[10])*(1+.028*(lv[4]+lv[5]+lv[11]));
 const lengthBonus=Math.min(c.synergyCap,1+c.synergy*Math.max(0,state.wagons-24)*(1+.08*lv[2]));
 return raw*multi*lengthBonus*c.damageScale;
}
function cornerExpiry(corner,slowTier){if(!Number.isInteger(corner)||corner<0||corner>3)throw Error('corner index must be 0..3');return 18.5+Math.min(6.5,slowTier*.65);}
function spawnRate(time,c){const minutes=time/60;const pulse=time>=300&&time%300<20?1.35:1;return .85*c.enemy*Math.pow(1+minutes/12,c.spawnExp)*pulse;}
function enemyHp(time,c){const minutes=time/60;return 18*c.hp*Math.pow(1+minutes/20,c.hpExp)*(minutes>=30?1.14:1);}
function laneTrainCounts(time,wagons,c){
 const result=[0,0,0,0], pos=(time*c.engineSpeed%c.railLength+c.railLength)%c.railLength;
 for(let i=0;i<wagons;i++){
   const p=((pos-i*c.wagonGap)%c.railLength+c.railLength)%c.railLength;
   const arcCorners=[0,1175,1950,3125];
   let nearest=0, minDist=c.railLength;
   for(let q=0;q<4;q++){
     const raw=Math.abs(p-arcCorners[q]);
     const dist=Math.min(raw,c.railLength-raw);
     if(dist<minDist){minDist=dist;nearest=q;}
   }
   result[nearest]++;
 }
 return result;
}
function simulate(profileName,seed,overrides={}){
 const c={...BASE,...overrides}; const profile=PROFILES[profileName];if(!profile)throw Error("unknown profile");
 if(c.timeStep!==1)throw Error("The cohort model is calibrated for dt=1s only; dt changes require a separate convergence analysis.");
 const rng=seeded(seed); const s=makeState(); const lanes=Array.from({length:4},()=>[]);
 const weights=[.82+.36*rng(),.82+.36*rng(),.82+.36*rng(),.82+.36*rng()];
 const weightNorm=4/weights.reduce((a,b)=>a+b,0);
 for(let q=0;q<4;q++)weights[q]*=weightNorm;
 const worldTrait=.86+.28*rng(), rewardTrait=.90+.20*rng();
 let kills=0,leaks=0,spentScrap=0,peakBacklog=0,firstBuy=null,firstCar=null,stop="censored",ticks=0;
 let lastTime=0;const snapshots={};
 const dt=c.timeStep; const totalTicks=Math.floor(c.maxMinutes*60/dt);
 const initialHp=250;
 for(let tick=0;tick<totalTicks;tick++){
  const time=tick*dt;s.time=time;lastTime=time;ticks++;
  const er=econRates(s.levels[7]); s.tp+=dt*c.tp*er.tp;
  let pending=0;for(const list of lanes)for(const batch of list)pending+=batch.count;
  const pick=chooseBuy(s,profile,pending);
  if(pick>=0 && attemptBuy(s,pick)){if(firstBuy===null)firstBuy=time;}
  const cap=slotCapacity(s.levels[0]);
  if(s.wagons<cap){const price=11+2.3*(s.wagons-1);if(s.scrap+1e-10>=price){s.scrap-=price;spentScrap+=price;s.wagons++;if(firstCar===null)firstCar=time;}}
  const count=laneTrainCounts(time,s.wagons,c);
  const hp=enemyHp(time,c);
  const totalKps=wagonDps(s,profile,c)*coverage(s.levels)/(hp*1.17);
  const baseBirths=spawnRate(time,c)*dt*worldTrait*(.92+.16*rng());
  let totalQue=0;
  for(let q=0;q<4;q++){
    const births=baseBirths*weights[q]/4;
    lanes[q].push({time,count:births});
    const expiry=cornerExpiry(q,s.levels[8]);
    const engageAfter=Math.max(0,expiry-c.openingRangeSeconds);
    const exposure=.40/4+.60*count[q]/s.wagons;
    let attack=totalKps*dt*exposure;
    const cohorts=lanes[q];
    for(let j=0;j<cohorts.length&&attack>1e-9;j++){
      const b=cohorts[j];if(time-b.time <engageAfter)break;
      const hit=Math.min(attack,b.count);b.count-=hit;attack-=hit;kills+=hit;
    }
    while(cohorts.length && time-cohorts[0].time>=expiry){
      const removed=cohorts.shift();leaks+=removed.count;s.barrier-=removed.count*profile.leakFactor/(1+.08*s.levels[6]);
    }
    while(cohorts.length && cohorts[0].count<1e-9)cohorts.shift();
    for(const batch of cohorts)totalQue+=batch.count;
  }
  if(totalQue>peakBacklog)peakBacklog=totalQue;
  // This model does NOT pretend to simulate projectile collision, locomotive damage,
  // individual enemy species or boss physical attacks. These are separate acceptance gates.
  const buffs=econRates(s.levels[7]);
  const gained=(kills-(s.kills||0));
  s.kills=kills;
  s.xp+=gained*c.xp*rewardTrait*buffs.xp;
  s.scrap+=gained*c.scrap*rewardTrait*buffs.scrap;
  if((time+dt)%600===0)snapshots[(time+dt)/60]={wagons:s.wagons,nodes:s.nodes,barrier:+s.barrier.toFixed(2),kills:Math.round(kills)};
  if(s.barrier<=0){stop="escape";break;}
  if(s.wagons>50||s.nodes>120||s.xp<-1e-8||s.tp<-1e-8||s.scrap<-1e-8||!Number.isFinite(s.barrier))throw Error("model invariant violated");
 }
 return {minutes:stop==="censored"?c.maxMinutes:+(lastTime/60).toFixed(2),stop,wagons:s.wagons,nodes:s.nodes,barrier:+s.barrier.toFixed(3),firstBuy,firstCar,kills:Math.round(kills),leaks:Math.round(leaks),peakBacklog:+peakBacklog.toFixed(1),spentScrap:+spentScrap.toFixed(1),snapshots,trainHpModelled:false};
}
function quantile(a,f){return a[Math.min(a.length-1,Math.floor(f*a.length))].minutes;}
function sample(n=16,seedStart=751,overrides={}){
 const result={},strategies=Object.keys(PROFILES);
 for(const key of strategies){
   const array=Array.from({length:n},(_,i)=>simulate(key,seedStart+i*37,overrides)).sort((a,b)=>a.minutes-b.minutes);
   result[key]={p10:quantile(array,.1),p50:quantile(array,.5),p90:quantile(array,.9),above120:array.filter(z=>z.minutes>=120).length,censored:array.filter(z=>z.stop==="censored").length,wagons:array[Math.floor(n/2)].wagons,firstBuy:array[Math.floor(n/2)].firstBuy,firstCar:array[Math.floor(n/2)].firstCar};
 }
 return result;
}
if(typeof process!=="undefined"&&process.argv?.[1]?.includes("audit_balance_v2.mjs")){
 const n=Number(process.argv?.[2]||16);console.log(JSON.stringify({model:"v2 1-second age-cohort/4-corner, NOT real game",runs:n,results:sample(n)},null,2));
}

export { BASE, PROFILES, BRANCHES, slotCapacity, coverage, econRates, nodeCost, makeState, attemptBuy, refundRecent, creditUniqueKill, chooseBuy, wagonDps, spawnRate, enemyHp, cornerExpiry, laneTrainCounts, simulate, sample };

import { BASE, PROFILES, BRANCHES, slotCapacity, coverage, econRates, nodeCost, makeState, attemptBuy, refundRecent, creditUniqueKill, wagonDps, spawnRate, cornerExpiry, laneTrainCounts, simulate, sample } from "./audit_balance_v2.mjs";
import { readFileSync } from "node:fs";

// 16 independent defect/retest loops. "pass" means model- or data-level only.
function runAudit(tree,wagons,enemies){
 const rounds=[];
 const add=(id,title,baseline,action,ok,details,status=null)=>rounds.push({id,title,baseline,action,status:status|| (ok?"PASS_MODEL":"FAIL"),retestPassed:!!ok,details});
 const assert=(test,msg)=>{if(!test)throw Error(msg);};
 // 01. Original 1+5*10=51; 50-car UI promises 50.
 const oldMax=1+5*10;
 add("L01","객차 최대 수 50과 슬롯 노드 10단", "1+5×10=51", "마지막 노드만 +4, 절대상한 50",
 oldMax===51&&slotCapacity(9)===46&&slotCapacity(10)===50&&Array.from({length:11},(_,i)=>slotCapacity(i)).every((n,i)=>n<=50&&(i===0||n>slotCapacity(i-1))),
 {oldMax,cap9:slotCapacity(9),cap10:slotCapacity(10),lastMarginalGain:slotCapacity(10)-slotCapacity(9)});
 // 02. With XP only on kill, zero early kills is a no-purchase trap.
 let first=makeState();first.tp=1;
 const starterXp=first.xp; const bought=attemptBuy(first,0);
 add("L02","0킬 첫 연구 데드락","첫 20XP는 처치로만 확보 가능","런 시작 20XP 보급; TP는 30초 경과 필요",
 starterXp===20&&bought&&first.levels[0]===1,{starterXp,manualFirstPurchase:bought});
 // 03. 121 nodes but 10 identical summaries per branch.
 const milestones=tree.nodes.filter(n=>n.milestone);
 const milestoneIds=new Set(milestones.map(n=>n.milestone.effectId));
 const validRefs=tree.nodes.every(n=>n.requires.every(ref=>tree.nodes.some(m=>m.id===ref)));
 add("L03","121노드의 고유 선택과 연결성","같은 가지 10단 설명이 동일","깊이 4·7·10에 계통별 고유 마일스톤 36개 정의",
 tree.nodes.length===121&&tree.branchCount===12&&milestones.length===36&&milestoneIds.size===36&&validRefs&&milestones.every(n=>n.milestone.runtimeImplementationRequired),
 {nodes:tree.nodes.length,branches:tree.branchCount,milestones:milestones.length,actualRuntimeEffects:"not implemented"}, "PARTIAL_DESIGN");
 // 04. 114% coverage is not coverage.
 const high=coverage([0,0,0,0,10,0,0,0,10,10,0,0]);
 add("L04","커버리지 1 초과","구 모델 max 1.14","물리적 사격 가용률 0..1 범위로 제한",
 high===1&&coverage(Array(12).fill(0))>=0,{legacyMaximum:1.14,newMaximum:high});
 // 05. Old threshold = rate*18.5 allowed an increasing "enemy buffer".
 const oldWaitAt30=30*18.5;const fixed=cornerExpiry(0,0);
 add("L05","적 발생률과 탈출시한 분리","spawnRate×18.5로 허용 적수가 증가","생성시각 별 코호트에 코너별 독립 이동 기한 부여",
 cornerExpiry(0,0)===18.5&&cornerExpiry(0,10)===25&&oldWaitAt30===555&&fixed===18.5,
 {oldRate30Capacity:oldWaitAt30,newCornerSeconds:fixed,newSlow10Seconds:cornerExpiry(0,10)});
 // 06. Wave doc says 5-min for 20s; old model was every 10-min for 40s.
 const pulseAt=(t)=>spawnRate(t,BASE)/(.85*BASE.enemy*Math.pow(1+(t/60)/12,BASE.spawnExp));
 const p300=pulseAt(300),p319=pulseAt(319),p320=pulseAt(320),p600=pulseAt(600);
 add("L06","웨이브 사건 주기","모형 10분마다 40초, 문서 5분마다 20초","300초 주기 ×20초 파동으로 수정",
 p300>1.3&&p319>1.3&&Math.abs(p320-1)<1e-8&&p600>1.3,
 {t300:p300,t319:p319,t320:p320,t600:p600});
 // 07. Old index quarter != actual unequal-sided rectangular arc corner.
 const cc=[0,1175,1950,3125].map(arc=>laneTrainCounts(arc/BASE.engineSpeed,1,BASE));
 const count50=laneTrainCounts(1234,50,BASE);
 add("L07","사각 레일 실제 모서리와 4레인 타겟 일치","원주를 단순 4등분해 각 모서리로 간주","호장 0/1175/1950/3125px 최근접 코너 매핑",
 cc.every((arr,i)=>arr[i]===1)&&count50.reduce((a,b)=>a+b,0)===50,
 {corners:cc,count50});
 // 08. Level purchase must be atomic and never negative; refund only within single no-reward tick.
 const st=makeState();st.tp=0;const before=[st.nodes,st.tp,st.xp];
 const blocked=!attemptBuy(st,0);const unchanged=JSON.stringify([st.nodes,st.tp,st.xp])===JSON.stringify(before);
 st.tp=1;const paid=attemptBuy(st,0,true);const refund=refundRecent(st);
 const zeroed=st.nodes===0&&st.levels[0]===0&&st.tp===1&&st.xp===20;
 add("L08","자원 부족 구매·취소의 원자성","노드 효과와 자원을 따로 갱신하면 중복/음수 위험","이중 자원 확인 후 동시 차감, 유효할 때만 현재 틱 취소",
 blocked&&unchanged&&paid&&refund&&zeroed,
 {blocked,unchanged,paid,refund,zeroed});
 // 09. Refund game-time exploit: free benefit while 5s purchase reversal was allowed.
 const rr=makeState();rr.tp=1;attemptBuy(rr,0,true);rr.time=1;const afterTick=refundRecent(rr);
 const rr2=makeState();rr2.tp=1;attemptBuy(rr2,0,true);creditUniqueKill(rr2,{hp:0,rewarded:false},2,1);
 const afterReward=refundRecent(rr2);
 add("L09","초반 업그레이드 환불 악용","5초간 구매 효과를 사용하고 전액 환불 가능","효과/보상 적용 전 동일 틱에서만 전액 취소",
 afterTick===false&&afterReward===false,{refundAfterOneTick:afterTick,refundAfterReward:afterReward});
 // 10. Same enemy death could credit twice.
 const rw=makeState(); const en={hp:0,rewarded:false};const x0=rw.xp,sc0=rw.scrap;
 const once=creditUniqueKill(rw,en,7,2);const twice=creditUniqueKill(rw,en,7,2);
 add("L10","처치 중복 보상과 XP·고철 인플레이션","중복 사망 이벤트에 무제한 보상 위험","개별 적 rewarded 플래그로 수령 1회 제한",
 once&&!twice&&rw.xp-x0===7&&rw.scrap-sc0===2,{once,twice,xpGained:rw.xp-x0,scrapGained:rw.scrap-sc0});
 // 11. Model typed coaches vs all equivalent DPS; actual individual weapon effects remain unimplemented.
 const coach=makeState();coach.wagons=10;
 const dps=Object.fromEntries(Object.entries(PROFILES).map(([id,p])=>[id,+wagonDps(coach,p,BASE).toFixed(2)]));
 const variation=new Set(wagons.cars.map(c=>c.baseDps)).size;
 add("L11","36종 객차 계열 차별화","기존 시뮬은 모든 객차를 20DPS로 동일 처리","새 모형에 5전략별 객차 공격/내구 대리계수 추가",
 variation>1&&dps.optimizer>dps.artillery&&dps.artillery>dps.armored&&dps.armored>dps.balanced&&dps.economist===dps.balanced,
 {individualWagons:wagons.cars.length,distinctBaseDps:variation,proxyDps10Cars:dps,fullWeaponMechanics:"not implemented"},"PARTIAL_DESIGN");
 // 12. Economic growth multiplying indefinitely by tiers.
 const cap0=econRates(0),cap10=econRates(10),cap30=econRates(30);
 add("L12","경제 성장 계수 상한","시간·경험·고철 증가율 무제한 누적 위험","시간 24%, XP 28%, 고철 30%에서 최대 배율 고정",
 cap0.tp===1&&cap10.tp<=1.24&&cap10.xp<=1.28&&cap10.scrap<=1.30&&JSON.stringify(cap10)===JSON.stringify(cap30),
 {at0:cap0,at10:cap10,at30:cap30});
 // 13. 5s model has material timestep sensitivity; refuse silent variable timestep.
 let dtRejected=false;try{simulate("balanced",751,{timeStep:5});}catch(error){dtRejected=/dt=1s/.test(error.message);}
 add("L13","5초 간격에서 발생하는 급격한 결과 차이","다른 틱 간격에서 순위와 생존시간 흔들림","새 코호트 모델은 dt=1초 고정, 불가피한 변경은 별도 재검증",
 dtRejected,{rejectedCoarseTimestep:dtRejected,realEngineFixedTick:"60Hz planned only"});
 // 14. R14 was invalid; R15 numerical tuning is checked across four untouched holdout seed groups.
 const current=sample(32,751);
 const holdoutGroups=[50021,90001,133711,310001].map(seed=>({seed,metrics:sample(32,seed)}));
 const ordered=Object.values(current).map(v=>v.p50);
 const range=+(Math.max(...ordered)-Math.min(...ordered)).toFixed(2);
 const survival120=Object.values(current).reduce((sum,v)=>sum+v.above120,0);
 const spread=range/(ordered.reduce((a,b)=>a+b,0)/ordered.length);
 const positive=Object.values(current).every(v=>v.firstBuy!==null&&v.wagons<=50);
 const holdStats=holdoutGroups.map(g=>{
   const values=Object.values(g.metrics), med=values.map(v=>v.p50);
   return {seed:g.seed,above120:values.reduce((sum,v)=>sum+v.above120,0),medians:Object.fromEntries(Object.entries(g.metrics).map(([k,v])=>[k,v.p50])),spreadPercent:+((Math.max(...med)-Math.min(...med))/(med.reduce((a,b)=>a+b,0)/med.length)*100).toFixed(1)};
 });
 const calibrated=positive&&survival120>=16&&survival120<=56&&spread<=.25&&holdStats.every(h=>h.above120>=16&&h.above120<=56&&h.spreadPercent<=25);
 add("L14","120분 균형 목표 재검정","기존 R14: 160/160(100%) 생존, 대기열 편향","R15 후보: 고정 학습 시드 160런 + 4개 미사용 홀드아웃 각 160런, 1초 코호트와 4코너 적용",
 calibrated,{trainRuns:160,holdoutRuns:640,trainingP50:Object.fromEntries(Object.entries(current).map(([p,v])=>[p,v.p50])),trainAbove120:survival120,trainSpreadPercent:+(spread*100).toFixed(1),holdouts:holdStats,interpretation:"heuristic mean-field ONLY, not actual skilled-player 120-minute survival rate"},calibrated?"PASS_MODEL":"UNRESOLVED_BALANCE");
 // 15. Locomotive 250HP defeat unmodelled, caught as blocking risk.
 const run=simulate("balanced",751);
 add("L15","기관차 체력 0 패배 판정","구 모델은 방벽만 패배 조건으로 사용","새 모델도 아직 물리 보스·기관차 피격 판정 없음: 구현 게이트로 분리",
 run.trainHpModelled===true,
 {runHasHullPhysics:run.trainHpModelled,hpPlanned:250,runStop:run.stop},"UNRESOLVED_RUNTIME");
 // 16. Rectangular battlefield center is equidistant from every corner.
 const distance=Math.hypot(1175/2,775/2);
 const delays=[0,1,2,3].map(q=>cornerExpiry(q,0));
 add("L16","중앙 구멍에서 네 모서리까지 거리 대칭","초기 모형에 모서리별 17/18/19/20초 고정 속도 차이","대칭 거리로부터 동일 18.5초 도착시간을 사용하고 모서리별 개체 속도 차이는 후속 구현",
 delays.every(x=>x===18.5)&&Math.abs(distance-702.8)<1&&new Set(delays).size===1,{centerToCornerPx:+distance.toFixed(2),cornerTimesSec:delays});
 const stats={total:rounds.length,passModel:rounds.filter(r=>r.status==="PASS_MODEL"&&r.retestPassed).length,partial:rounds.filter(r=>r.status==="PARTIAL_DESIGN").length,unresolved:rounds.filter(r=>r.status.startsWith("UNRESOLVED")).length};
 return {model:"Audit v2; NOT an actual Godot playtest or engine test",stats,rounds,cohortResult:current};
}
if(typeof process!=="undefined"&&process.argv?.[1]?.endsWith("run_logic_balance_audit.mjs")){
 const load=(name)=>JSON.parse(readFileSync(new URL(name,import.meta.url),"utf8"));
 console.log(JSON.stringify(runAudit(load("./tree_nodes.json"),load("./wagons.json"),load("./enemies.json")),null,2));
}

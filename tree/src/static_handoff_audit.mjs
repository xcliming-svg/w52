import {readFileSync} from "node:fs";
const read=(name)=>readFileSync(new URL(name,import.meta.url),"utf8");
function audit(A,C,M,I,R,T,W,E) {
 const has=(s,t)=>s.includes(t),ts=q=>M.tasks.some(x=>(x.action+" "+x.sourcePath+" "+x.acceptance).includes(q));
 const rounds=[
 ["A01","W52 기존 프로젝트를 덮어써도 되는가?","원본 W52 보존, tree/src/project.godot 독립 프로젝트","AGENTS§0,CONTRACT C01,P00",has(A,"기존 W52")&&has(C,"tree/src/project.godot")&&ts("독립 Godot")],
 ["A02","웹을 C#·Vulkan·멀티스레드로 구현하는가?","Godot4.7.2 GDScript Compatibility WebGL2 단일스레드","AGENTS§0/6,P00/P13",has(A,"GDScript")&&has(A,"단일 스레드")&&ts("Web 단일 스레드")],
 ["A03","소스·문서·배포 산출물 위치는?","게임 source tree/src, 문서 tree/docs, build tree/build, CI만 루트 workflow","AGENTS§0,MANIFEST",has(A,"tree/src/")&&has(A,"tree/docs/")&&has(C,"tree/build/web")],
 ["A04","16 대구는 정확히 무슨 규격인가?","기본 16:9, 1920×1080 디자인·1280×720 기본창, 16:10 레터박스","AGENTS§0,CONTRACT C01",has(A,"16 대구")&&has(C,"1920×1080")&&ts("16:9")],
 ["A05","게임은 어떤 씬부터 어떻게 종료되는가?","BOOT→TITLE→MENU→RUN→PAUSE/RESULT→MENU","CONTRACT C02,P01",has(C,"BOOT→TITLE")&&ts("게임 상태기계")&&ts("패배 및 기록 화면")],
 ["A06","사각 레일 코너에서 차량이 찢어지면?","둘레3900·28px 객차 간격·호장 경로; 회전만 보간","CONTRACT C03,P03",has(C,"3900px")&&has(C,"28px")&&ts("사각 3900px")],
 ["A07","W10을 연구하면 51량이 되는가?","W01~09 +5, W10 +4로 총50량","CONTRACT C07,tree_nodes W10,P03",T.nodes.find(x=>x.id==="W10")?.value===4&&has(C,"W10은 +4")&&ts("최대50량")],
 ["A08","4모서리에서 적이 왜 비대칭으로 탈출하는가?","중앙→코너 동거리, 실제 좌표로 탈출; 18.5초는 집계 근사","CONTRACT C04,P04",has(C,"실제 좌표 판정")&&has(C,"18.5초")&&E.enemies.length===14&&E.enemies.every(x=>x.canEscape===true&&x.escapeDamage>=0.5&&x.escapeDamage<=3)&&ts("4모서리 목표")],
 ["A09","패배는 방벽만 0인 경우인가?","방벽30 소진 또는 기관차 HP250 소진이 별개 게임오버","CONTRACT C04,P03/P06",has(C,"기관차 HP250")&&has(C,"방벽30")&&ts("방벽0/기관차HP0")],
 ["A10","36종 객차가 전부 색상 차이인가?","12무기 패밀리×3등급, 12무기별 발사·피격 로직 따로 구현","CONTRACT C05,P05",W.cars.length===36&&has(C,"서로 다른 실제")&&W.cars.every(x=>x.family!=="support"||x.role==="support")&&W.cars.every(x=>x.family!=="sniper"||x.hitBehavior==="pierce")&&M.tasks.filter(x=>x.phase==="P05"&&x.sourcePath.includes("gun_")).length===12],
 ["A11","탄막이 똑같은 적에게 무한 피해를 줄 수 있나?","hitID·swept collision·상태 DOT 독립 tickID 중복방지","CONTRACT C06,P05/P06",has(C,"고유 hitID")&&ts("타격ID 중복")&&ts("고속탄 추적")],
 ["A12","트리 121개의 특별한 노드가 무엇인가?","12×10+중앙, 깊이4/7/10마다 36개 effectId 고유 실제 기능","CONTRACT C07,tree_nodes,P07",T.nodes.length===121&&T.nodes.filter(x=>x.milestone).length===36&&ts("고유 36효과")],
 ["A13","첫 구매에서 XP가 없어서 진행불가 아닌가?","XP20·TP0 시작, 약 30초부터 첫 연구 가능","CONTRACT C07,P08",has(C,"XP20")&&ts("시작TP0/XP20")],
 ["A14","환불과 전체초기화로 재화를 복제하면?","효과 적용 전 같은 물리틱 취소, 초기화1회·70%·초과차량 보관","CONTRACT C07,P07",has(C,"같은 물리틱")&&has(C,"70%")&&ts("효과 발동전 취소")],
 ["A15","경제 상한 이후 E09/E10이 죽은 노드가 되나?","기초 수익 캡과 별개 E07~10 salvage 확률 3%p씩","CONTRACT C07,tree_nodes E07~10,P08",["E07","E08","E09","E10"].every(id=>T.nodes.find(x=>x.id===id)?.extraEffects?.[0]?.value===.03)&&has(C,"E7~E10")&&ts("salvage+3%p")],
 ["A16","50량 강체 체인으로 물리 충돌 폭발하지 않나?","호장 수학 이동·물리 강체 예산·경량 적/탄 풀링","CONTRACT C06/P10",has(C,"50량 RigidBody")&&ts("PhysicsServer2D")],
 ["A17","파편 시각효과를 줄이면 게임 판정도 느려지나?","VFX와 gameplay 피해 판정 분리·저사양/저섬광 보조","CONTRACT C08,P09",has(C,"시각 파편과 게임플레이 피해 판정은 독립")&&ts("적 죽음 도형 파편화")&&ts("광과민 보호")],
 ["A18","긴 세션에서 중단 저장·배속 기록은 어떻게 되나?","schema_version=1, 60초 저장·2백업·실시간/배속 기록 구분","CONTRACT C09,P12",has(C,"schema_version=1")&&has(C,"60초")&&ts("버전 있는 중단저장")&&ts("배속·일시정지 보조기록 분리")],
 ["A19","기존 W52 Pages를 덮어쓰지 않고 웹게임을 추가하나?","main /tree/·devel /tree-devel/ 선택적 빌드·2개 workflow 증분 수정","AGENTS§6,STEAM_RELEASE,P13",has(A,"publish-devel.yml")&&has(R,"site/tree-devel")&&ts("Pages 재게시")],
 ["A20","실행 테스트 없이 코드 100%면 Steam 출시를 주장하나?","아니오. 179/179 정적 소스와 Steam 5분 실행·Valve 리뷰를 분리","AGENTS§4,STEAM_RELEASE,P14",has(A,"RUNTIME_VERIFIED")&&has(R,"5분")&&has(I,"런타임")&&ts("Steam 검토")]
 ];
 const extra={
 count:M.tasks.length, uniqueIds:new Set(M.tasks.map(x=>x.id)).size, plannedCount:M.tasks.filter(x=>x.status==="TODO").length,
 allEvidenceBlank:M.tasks.every(x=>x.evidence.length===0),nonEmptyAcceptance:M.tasks.every(x=>x.acceptance.trim().length>8),
 allPhases:M.groups.length===16, allPrimaryData:T.nodes.length===121&&W.cars.length===36&&E.enemies.length===14,
 full36Milestones:T.nodes.filter(x=>x.milestone).length===36
 };
 return {checks:rounds.map(([id,question,resolution,evidence,passed])=>({id,question,resolution,evidence,pass:passed===true,kind:"static document+data consistency"})),extra};
}
const result=audit(read("../AGENTS.md"),read("../docs/CONTRACT.md"),JSON.parse(read("../docs/IMPLEMENTATION_MANIFEST.json")),read("../docs/IMPLEMENT_COMMAND.md"),read("../docs/STEAM_RELEASE.md"),JSON.parse(read("./tree_nodes.json")),JSON.parse(read("./wagons.json")),JSON.parse(read("./enemies.json")));
console.log(JSON.stringify(result,null,2));
if(result.checks.some(x=>!x.pass))process.exitCode=1;

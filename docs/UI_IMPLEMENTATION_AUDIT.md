# W52 UI 구현설계 대조 및 검증 기록

- 점검 기준일: 2026-11-02
- 기준 문서: docs/UI_LAYOUT_DESIGN.md
- 기준 구현: feature/w52-build-first-ui, devel 에 동일한 UI 관련 파일만 선택 반영
- 검증 범위: Godot 소스/씬 정적 대조 + GitHub Actions 헤드리스 씬·52회 흐름·Web Export
- 실제 PC/웹 브라우저 플레이 QA·시각적 렌더링은 수행하지 않음

## 1. 설계-소스 대조

| 승인 요구 | 구현 근거 | 상태 |
|---|---|---|
| 16:9 화면 비율과 1920×1080 논리 좌표 | project.godot: viewport 1920×1080, stretch canvas_items+keep | 정적 일치 |
| 기존 메뉴·일시정지·설정 모두 공통 규모 | scripts/ui_style.gd, main.gd Theme 폰트/크기, title.gd, title.tscn, settings_menu.gd | 정적 일치 |
| 좌 메인 1376/우 전장 544 고정 | ui_style.gd 상수와 game.gd 직사각형 배치 | 정적 일치 |
| W52/작전설계·트리 제목/범례 제거 | game.gd 헤더 및 트리 출력 문자열 | 정적 일치 |
| 노드 호버/선택 1.12배·선택 경로 원선 색 변경 | game.gd _draw_tree() | 정적 일치, 시각 QA 필요 |
| 노드 선택시 트리 중앙 이동 | game.gd _select_node(), camera_target=(688,446)-node.p, _process() 보간 | 정적 일치, 체감 QA 필요 |
| 노드 정보 옆 창·불필요 메타 제거 | game.gd _draw_popup(), _update_popup() | 정적 일치 |
| 5개 대화와 Space 진행·대사 종료 시 노드 포커스 | game.gd _input(), _advance_dialogue(), _draw_dialogue() | 정적+헤드리스 일치 |
| 대화 없는 때 숨기고 해설 아이콘 표시 | game.gd phase 조건부 _draw_dialogue() | 정적 일치 |
| 도움말 미래 열람 불가·주차 인덱스 미표시·하단 정렬 | _change_help(), _help_text(), 하단 (0,976,1376,104) | 정적+헤드리스 일치 |
| 전장 적 위/아군 아래·가변 격자·칸 46px | _grid_size(), _draw_field() | 정적 일치 |
| 전장 아군→왼쪽 트리 포커스 | _click_ally() → _select_node() | 정적 일치 |
| '전투 시간' 라벨 제거·붙은 1×/2× 버튼 | _create_controls()에서 x=1688,1791 양쪽 버튼, 단일 speed 값 | 정적 일치 |
| 전투 정보에서 시간 접두사 제거·로그만 스크롤 | _refresh_log()의 텍스트와 ScrollContainer 한 개 | 정적 일치 |
| 준비/진행/결과, G 체크, 중복 클릭 방어 | _battle_action(), _process() | 정적+헤드리스 일치, 전투 수치는 시연 |
| 52주 × 1회 진행 및 결과 | tests/w52_ui_smoke.gd 시뮬레이션 루프, game.gd 전이 | 헤드리스 PASS |
| 저장·이어하기·구 버전1 복원 | main.gd, save_manager.gd 버전2, game.gd snapshot/restore_state | 정적+헤드리스 PASS |
| 신규 한글 문구 웹 번들 글리프 | assets/fonts/nanum-*.woff2 19개, main.gd 기본 폰트 fallbacks | Web Export 자산 포함 확인, 육안 QA 미실시 |

## 2. 구현 및 수정/재검증 순서

1. 메인 메뉴·타이틀이 존재하는 최신 origin/main 75d1c397을 기준으로 feature/w52-build-first-ui 분리. 로컬 w52는 오래된 데모이므로 기존 파일을 덮어쓰지 않고 원격 소스에서 작업.
2. 메인 게임 화면, 해상도, 공통 메뉴 크기, 저장 버전2, 문서를 기능 브랜치에 커밋하고 해당 파일만 devel에 옮김.
3. 최초 devel GitHub Actions 실행 41358450584: 임포트·기본 씬 스모크·stable/devel Web Export PASS.
4. 웹 한국어/기호 누락 위험을 확인하여 Nanum Gothic OFL subset 19개와 공유 Font fallbacks 추가. Actions 41358983653 Web Export PASS.
5. 타이틀 텍스트·로고 플레이스홀더·설정 행·Theme 기본 폰트 크기까지 FHD 규격으로 수정.
6. Godot SceneTree 헤드리스 시나리오 테스트 추가: 52개 주차, 대화, 도움말 제한, 트리 선택/배치, 중복 방지, 전투 종료, 저장/복원.
7. Actions 41359288386 빌드/헤드리스 PASS. 잡 로그에 'W52_UI_SMOKE_OK: 52 battles, dialogues, help gating, deployment, save/restore, 1920x1080' 표시, ERROR/Parser Error 없음.

## 3. 아직 검증하지 않았거나 기획 결정이 필요한 부분

- 실제 전투 AI·피해·승패 판정·유닛별 코스트는 미구현. 현재는 전투 관전 시간과 정해진 결과만 보여주는 동작 검증용 시연.
- 52주 고유 스토리/도움말 원고와 정확한 노드 해금 주차·경제값은 미확정. 반복 문구/임시 40G·70G·18초를 쓰므로 밸런스 검증 대상이 아님.
- 애니메이션의 실제 재생 품질, 1280×720에서의 읽기 편의, 팝업 충돌 및 클라이언트 웹폰트 렌더링은 직접 플레이 검수 필요.
- PC/Web 메뉴 조작, 저장소 지속성, 브라우저의 전체화면 권한, 52주 전체 사용감은 아직 실제 사용자 테스트 미실시.
- 로컬 C:\GPT-Workspace\w52의 Git 작업 상태 확인은 도구 제약으로 불가. 위 검증은 원격 feature/devel Git 트리 기준이며 로컬 작업트리를 동기화했다고 주장하지 않음.

## 4. 재대조 결론

- 요구된 화면 영역·폰트·노드/대화/전장 연동은 **코드 기준 정적 일치**.
- 기본 프로젝트 임포트, Godot SceneTree 52주 상태 스모크, Web Export는 **CI PASS**.
- 시각적 완성도와 정식 전투/스토리 콘텐츠는 **미검증·별도 후속 개발 범위**.
- main은 수정하거나 devel 전체를 병합하지 않음.

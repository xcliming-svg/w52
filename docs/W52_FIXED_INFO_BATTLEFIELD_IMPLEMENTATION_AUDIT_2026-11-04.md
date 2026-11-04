# W52 2026-11-04 구현설계 01~05 코드 대조·검증 기록

- 작업 브랜치: `feature/fixed-node-info-battlefield-implementation-20261104` (GitHub 최신 `main` `3a85347295377557a7b2c57d539206c4f1d01518`에서 분기).
- 기준 설계: 같은 브랜치로 가져온 `docs/W52_01_*` ~ `docs/W52_05_*`의 2026-11-04 설계서 5개.
- 대조 대상: `scripts/game.gd`, `scripts/save_manager.gd`, `tests/w52_ui_smoke.gd`, 기존 `main.gd`·`project.godot`·`scenes/game.tscn` 인터페이스.
- 판정 정의: **일치(정적)** = 코드·자료 계약·이벤트 경로를 대조하여 부합함. **헤드리스 PASS** = GitHub Actions Godot 4.7.2 씬 스모크 실행 결과 확인. **미검증** = 실제 PC/브라우저 렌더링·스크롤·마우스 조작/성능을 직접 검증하지 못함. **불일치** = 설계와 소스가 확인 가능하게 다른 경우.
- GitHub Actions 실제 실행: [Godot Build 41800013533](https://github.com/xcliming-svg/w52/actions/runs/41800013533)에서 안정판/개발판 임포트, 씬 스모크, 52주·배치·버튼·액션 매트릭스·v2/v3/v4 저장 검증, Web Export, 아티팩트 검사가 성공. [Pages 41800199084](https://github.com/xcliming-svg/w52/actions/runs/41800199084)에서 게시 성공 확인. **실제 PC/브라우저 화면·입력은 수행하지 않음**.

## 01 고정 정보창

| 요구사항 | 판정 | 실제 코드·씬·입력·검사 근거 |
|---|---|---|
| 단일 고정 패널, 위치/크기 불변 | 일치(정적) | `game.gd::INFO_PANEL_RECT=Rect2(930,170,420,560)`, `_create_controls()`에서 `NodeInfoLayer` 위치/크기 설정, `_info_panel_rect()`; 노드 상대 팝업 계산 제거 |
| 전장/헤더/대화와 패널 비겹침 | 일치(좌표 대조), 미검증(실측) | x=930..1350은 전장 x>=1376 밖, y=170..730은 헤더 0..84/대화 y>=778 밖. 픽셀·폰트 렌더 미검증 |
| 헤더·스크롤 본문·고정 액션 푸터 | 일치(정적), 미검증(실측) | `info_title`, `info_status`, `info_scroll`, `info_reason`, `deploy_button`, `secondary_button`; overflow·스크롤 위치는 실사용 미검증 |
| 트리 정의와 전장 개체가 정보창 하나 공유 | 일치(정적) | `_resolve_info_context()` → `_refresh_info_panel()`; 개별 업그레이드 떠다니는 창 제거 |
| 정보창 클릭/휠/드래그가 트리 패닝을 시작하지 않음 | 일치(정적), 헤드리스 입력 테스트 PASS·실브라우저 미검증 | `NodeInfoLayer`·`info_scroll` 마우스 STOP, `_gui_input()`의 `INFO_PANEL_RECT` 가드, `_node_at()` 제외 |
| 112% 선택·8px 임계값·20노드/19선·24강화 유지 | 일치(정적), 헤드리스 씬 PASS | `NODES` 20, parent 19, `UPGRADES` 12×2, `_node_half_size`/focus 1.12, `DRAG_THRESHOLD=8`; 스모크 테스트 기술트리 계약 |
| 패널 뒤 노드를 가시로 오인하지 않음, 49 pan점과 12프레임 | 일치(정적), 헤드리스 CI PASS | `_readable_tree_area()`의 x<918 및 대화 상단 경계, `_clamp_pan()`; `tests/w52_ui_smoke.gd` 49점·12프레임 테스트 유지 |
| PC/Web 단일 프로젝트 및 Canvas 좌표 | 일치(설정·코드), 미검증(환경) | `project.godot`의 동일 1920×1080 캔버스/1280×720 창/Compatibility, 플랫폼별 별도 씬 없음 |

## 02 첫 HQ 선택과 선택 원점

| 요구사항 | 판정 | 실제 코드·상태·검사 근거 |
|---|---|---|
| 새 게임 처음 HQ 선택 및 HQ 정보 표시 | 일치(정적), 헤드리스 씬 PASS·실브라우저 미검증 | `selected_id="hq"`, `_set_week_intro()`, `_ready()->_refresh_all()`; `_check_integrated_tree()`에서 기본 HQ/제목 확인 |
| v2/v3/신규 v4 이어하기 HQ 선택 | 일치(정적), 헤드리스 저장 fixture PASS | `restore_state()`의 HQ 초기화, `_refresh_all()` 및 저장 변환 테스트 |
| 다음 주 진입 HQ·카메라 리셋, 기존 시설 유지/배치 초기화 | 일치(정적), 헤드리스 52주 PASS | `_battle_action() -> _set_week_intro()`; `placements.clear()`, `owned_buildings` 불변 |
| 직접 트리 선택은 HQ 기본값을 덮어쓰고 지속 | 일치(정적) | `_select_node(id,user_input=true)`, `user_selected_context` |
| 전장 개체 선택/빈 아군 셀 클릭 시 컨텍스트 복귀 | 일치(정적) | `_select_field_instance()`, `_return_to_tree_context()`, 마지막 `selected_id` 보존 |
| W01 3번째 튜토리얼에서만 소총병 자동선택, 사용자 선택은 불변 | 일치(정적), 헤드리스 대화 테스트 PASS | `_advance_dialogue()`의 week==1 및 user_selected_context 가드, 새 테스트 |
| ESC/일시정지·대화 공존 | 일치(기존 경로 보존), 미검증(실제 일시정지) | ESC 매핑 변경 없음; `main.gd`/일시정지 씬 미수정 |

## 03 노드 종류별 정보

| 요구사항 | 판정 | 실제 코드·UI·데이터 근거 |
|---|---|---|
| 건물 8 / 유닛 12 유형 제목·상태/설명·후보 주차 | 일치(정적), 미검증(폰트 실측) | `_render_info_content()`, `_refresh_info_panel()`가 기존 `NODES`의 kind/detail/week 이용 |
| HQ 직계 4시설, 시설 부모 및 연계 시설 링크 | 일치(정적) | `_add_info_link()`, `_focus_requirement()` 및 `NODES.parent` 조회 |
| 생산시설/기술시설 연계 병종·직접/간접 선행 | 일치(정적) | `_related_unit_ids()`, `requires` 및 `radar → drone_hangar` 간접 체인; 연계와 배치 가능 별도 판정 |
| 1~3개 이상 요구시설 보유·미보유 목록 | 일치(정적), 미검증(스크롤 실측) | `requires` 반복, `_has_building()`, `info_scroll` |
| 유닛 역할·HP/사거리/공격 수치 미정 표시 | 일치(정적) | 미승인 수치 모델 추가 없음, `HP: 미구현`, `사거리: 미정`, `공격력/공격주기: 미정` |
| 12×2 강화 A/B는 조회만, 트리 내부 노드로 추가 없음 | 일치(정적), 미검증(실제 렌더) | `UPGRADES` 조회, `_render_info_content()`; 업그레이드 구매 버튼·효과 없음 |
| 개별 유닛 ID, 위치, 같은 병종/전체 배치 수 | 일치(정적) | `FIELD_INSTANCE`, `instance_id,col,row`, `_unit_count()` |
| 전투/결과 조회 전용 | 일치(정적) | `_get_info_actions()`, `_remove_placed_instance()` 및 드래그의 phase 가드 |

## 04 패널 액션

| 요구사항 | 판정 | 코드·상태 전이·검사 근거 |
|---|---|---|
| HQ 건설/배치 없음, 직계 시설 선택 | 일치(정적) | `_get_info_actions()` root 분기, `_render_info_content()` 링크 |
| 건물 보유 시 건설 숨김 / 시연 건설은 요건 충족 시에만 | 일치(정적) | `_get_info_actions()` + 실행 핸들러 `_build_selected()`; 비용/G 수정 없음 |
| 미충족 건물/유닛 버튼 비활성 및 사유 안내 | 일치(정적) | 주차·부모/필수시설·단계·12칸 평가 `_get_info_actions()`, `info_reason` |
| 필요시설 찾기/관련 병종 보기 실제 노드 포커스 | 일치(정적), 헤드리스 버튼 신호 PASS·실브라우저 미검증 | `_focus_requirement()`, 필요 시 `full_tree_view` 전환; `_show_related_units()` + 선택 링크 |
| 배치 버튼은 새 유닛 생성 전 PLACE_NEW 대기 진입 | 일치(정적) | `_on_info_primary_action()` → `_begin_new_unit_placement()` (생성 없음) |
| 대기 취소 vs 개체 1기 배치 취소 분리 | 일치(정적) | `_cancel_pending_placement()` vs `_remove_placed_instance()` |
| 이미 건설, 12칸 초과, 중복 배치 대기 방지 | 일치(정적), 헤드리스 중복입력 PASS·실브라우저 미검증 | `_build_selected()` 보유 가드; `_begin_new_unit_placement()` 상태/슬롯 가드; 스모크 테스트 추가 |
| 유보 기능 경계만, 버튼 실행 불가 | 일치(정적) | `_request_upgrade_purchase/_request_building_refund/_request_paid_unit_production/_request_range_overlay/_request_combat_reposition`가 false만 반환; 실제 호출 버튼 없음 |
| 정책 미정 가격·환불·전투 이동·강화 적용 미구현 | 일치(정적) | 승인되지 않은 경제/전투 게임 상태 및 저장 항목 추가 없음 |

## 05 우측 전장 및 저장

| 요구사항 | 판정 | 코드·입력·상태·저장·검사 근거 |
|---|---|---|
| PLACE_NEW 빈 아군 셀 클릭 시 1기 생성, 새 ID | 일치(정적), 헤드리스 입력 핸들러 PASS·실브라우저 미검증 | `_confirm_pending_at()`; `unit_%06d` ID, `placements.append`, 대기 해제 및 개체 선택 |
| PLACE_NEW 점유·적군·범위 밖 실패 시 대기 유지 | 일치(정적), 헤드리스 입력 핸들러 PASS·실브라우저 미검증 | `_is_ally_cell()`, `_instance_at_cell()`, 실패 로그와 미변경 모델 |
| 기존 개체 클릭 = 개체정보·기술트리 강조(정의정보로 대체 안 됨) | 일치(정적) | `_select_field_instance()`, `_active_tree_node_id()`, `_selected_ancestors()`, `selected_instance_id` |
| 8px 미만 클릭 / 8px 이상 드래그와 1회 드롭 확정 | 일치(정적), 헤드리스 입력 테스트 PASS·실브라우저 미검증 | `_update_field_drag()`의 `DRAG_THRESHOLD`, `_finish_field_interaction()`에서만 좌표 갱신 |
| 드래그 목표 점유·적군·범위 밖이면 이동/복제/교환 없음 | 일치(정적), 헤드리스 입력 테스트 PASS·실브라우저 미검증 | `_finish_field_interaction()`의 점유 및 아군 범위 가드와 거부 로그 |
| 개별 ID 유지, 배치 취소 시 선택 1기 제거 | 일치(정적) | `_instance_index()` 및 `remove_at(index)`; G·건물 배열 불변 |
| 빈 아군 칸 클릭 마지막 트리 정보로 복귀 | 일치(정적) | `_return_to_tree_context()` |
| 전투/결과 선택은 가능하지만 배치/이동/제거 금지 | 일치(정적) | phase 가드 및 액션 매트릭스, 새 스모크 테스트 |
| 전장 드래그가 트리 카메라를 이동시키지 않음 | 일치(정적), 헤드리스 입력 테스트 PASS·실브라우저 미검증 | `_start_field_interaction()` 카메라 타깃 중단, field drag 분리 |
| 격자 46px 및 주차별 6×6/8×8/10×8/10×10 | 일치(정적), 헤드리스 좌표 테스트 PASS·픽셀 QA 미검증 | `grid_size_for_week()`, `_grid_origin()`, `_field_cell()`, `_draw_field()`, 경계 테스트 |
| 12기 제한 및 매주 배치 초기화·시설 보존 | 일치(정적), 헤드리스 52주 PASS | `_get_info_actions()`, `_begin_new_unit_placement()`, `_confirm_pending_at()`, `_set_week_intro()` |
| 저장 버전 v4, 개체 ID/병종/셀 정수 저장 | 일치(정적), 헤드리스 저장 왕복 PASS | `SAVE_VERSION=4`, `snapshot()`, `save_game()` |
| v4 ID/종류/선행시설/주차/12기/격자·중복 엄격 거부 | 일치(정적), 헤드리스 CI PASS | `_valid_placements()`, `_valid_buildings()`; 잘못된 로드/저장 fixture |
| v2/v3 순서 유지 자동 배치 좌표 변환, 구 시연 ID 제외, v1 거부 | 일치(정적), 헤드리스 CI PASS | `_migrate_legacy_placements()`, `legacy_cell_for_index()`, `load_game()` 분기; v1/v2/v3 fixture |
| battle 저장 상태는 prepare로 복구 | 일치(정적), 헤드리스 파일 복구 PASS | 기존 `restore_state()` 처리 및 v3→v4 fixture |
| 20노드·19선·49점 패닝·52주·메뉴 경로·Web Export 회귀 | 일치(테스트 코드/기존 경로), 헤드리스·Web Export PASS·실브라우저 미검증 | `tests/w52_ui_smoke.gd` 회귀 테스트의 구조 확인; Godot CI/실제 PC·Web은 실행하지 않음 |

## 정적 검사·오류 수정 기록

1. 브랜치의 `scripts/game.gd`, `scripts/save_manager.gd`, `tests/w52_ui_smoke.gd`를 GitHub에서 재조회하고 31개 정적 계약 검사(공백, 들여쓰기, 충돌 마커, 중복 함수명, 괄호·따옴표 어휘 균형, 노드·강화 수, 고정 패널, HQ, 전장 조작·상태, 저장 v4·마이그레이션, 스모크 테스트 커버리지, 구 팝업 제거)를 수행: **31/31 PASS**.
2. 재검사 전에 테스트의 여러 줄 배열 들여쓰기 불일치를 발견하여 수정. 스모크 테스트 실제 실행 결과가 아니라 정적 소스 검사 결과임.
3. 재검사 전에 v4 개체 사전에 미승인 능력치 등 추가 필드가 저장될 여지를 발견하여 정확히 네 필드만 허용하도록 수정. 보유 건물의 부모·주차 검증을 유지.
4. 건물의 관련 병종 보조 버튼이 건설 전에도 의미 있게 노출되고 부족 시설 찾기를 우선하도록 조정. 정보창의 연결 기술시설·병종의 간접 선행 안내 추가. 메인 메뉴 경로의 HQ·무배치 테스트 보강. 정적 재검사 완료.
5. GitHub Actions Godot 4.7.2 실행에서 임포트·헤드리스 씬/입력/저장 테스트·Web Export가 모두 성공. 실제 PC/브라우저 픽셀·포인터·휠 조작·실측 폰트 렌더는 **미검증**이며 테스트 커버리지 밖의 동작까지 PASS라고 주장하지 않음.

## 잔여 상태와 외부 경계

- 확인 가능한 소스 계약에서 발견되어 미수정으로 남긴 **불일치: 없음**. 실사용 결과는 별도 검증 필요.
- 별도 결정 필요: 정식 HP·최대 HP·사거리(단위/판정 방식)·공격력·공격주기, 비용·환불·강화 구매·효과, 전투 중 재배치 정책. 값/구매 기능은 만들어 넣지 않음.
- 로컬 `C:\GPT-Workspace\w52`는 사용자가 제시한 Git 상태에서 `docs/WW52_TECH_TREE_IMPLEMENTATION_DESIGN_2026-11-04.md`, `scripts/game.gd`, `tests/w52_ui_smoke.gd` 수정 및 `w52_safe_local_apply.ps1` 미추적 상태. 기존 작업 보호를 위해 **로컬 경로는 수정하지 않음**. GitHub 원격 브랜치에서만 구현·배포 완료.
- AGENTS.md의 정책에 따라 로컬 게임 실행·실브라우저 QA는 수행하지 않음. `devel`에 제한된 기능 변경만 반영해 Actions 41800013533 헤드리스·Web Export PASS 및 Pages 41800199084 게시 성공을 실제 Job 단계에서 확인.
- 사용자 요청에 따라 `devel`에 이번 기능의 9개 파일만 fast-forward 반영, Pages `/devel/` 게시. `main`에는 변경·병합 없음.


## 2026-11-04 행 단위 재감사: 원본 5개 문서의 실질 행 전수 대조

원본의 **빈 줄과 제목/표 구분선은 제외**하고 각 설명·계약·표 데이터·시나리오 행을 문서 라인 기준으로 검사했다. 행별 '코드 일치'는 요구된 상태전이·함수·데이터 계약의 근거가 확인되었다는 의미이며, GitHub Actions 성공이 실제 브라우저 시각 정상성을 증명하지는 않는다. 테스트 항목 중 실제 브라우저 QA는 미검증으로 남긴다.

**실제 확인한 실행 로그:** 첫 devel run [41798608090](https://github.com/xcliming-svg/w52/actions/runs/41798608090)에서 GDScript 예약어 변수 파싱 실패 → 이름 수정. 두 번째 run [41798837262](https://github.com/xcliming-svg/w52/actions/runs/41798837262)에서 배치 테스트 입력 순서 오류 → 재선택 이벤트 추가. 이후 [41799013108](https://github.com/xcliming-svg/w52/actions/runs/41799013108), [41799501851](https://github.com/xcliming-svg/w52/actions/runs/41799501851), [41800013533](https://github.com/xcliming-svg/w52/actions/runs/41800013533)에서 Godot 4.7.2 안정/개발 임포트, 양쪽 헤드리스 스모크, Web Export, 검증 파일 업로드가 통과했다. [41799663156](https://github.com/xcliming-svg/w52/actions/runs/41799663156)에서 검증된 개발판의 Pages 게시가 성공했다. 마지막 액션 매트릭스 빌드의 [Pages 41800199084](https://github.com/xcliming-svg/w52/actions/runs/41800199084)에서도 다운로드·빌드 산출물 확인·Pages 배포 단계 **success**를 확인했다.

### W52_01: W52_01_FIXED_INFO_PANEL_IMPLEMENTATION_DESIGN_2026-11-04.md

| 원문 행 | 내용 요지 | 코드·검증 근거 | 판정 |
|---|---|---|---|
| 01:3 | - 문서 상태: **구현 지시용 상세 설계**, 코드 미구현. 좌표·레이아웃은 1920×1080 논리 해상도의 **제안 기본값**이며 시각 QA에서 조정 가능. | `원본 문서 기준` | 설계 시점의 설명 |
| 01:4 | - 기준: `AGENTS.md`, `docs/UI_LAYOUT_DESIGN.md`, `docs/WW52_TECH_TREE_IMPLEMENTATION_DESIGN_2026-11-04.md`… | `원본 문서 기준` | 설계 시점의 설명 |
| 01:5 | - 코드 기준: `main` 3a85347295377557a7b2c57d539206c4f1d01518 (`devel` 0e11827b72da6554fe6e62b3a762c890b713fd… | `원본 문서 기준` | 설계 시점의 설명 |
| 01:6 | - 연관 문서: 02 초기 HQ, 03 정보 요소, 04 버튼 액션, 05 전장 조작. 이 문서만으로 게임 룰·HP 수치를 만들지 않는다. | `원본 문서 기준` | 설계 시점의 설명 |
| 01:9 | 1. 노드 클릭·전장 유닛 클릭·트리 드래그 시 정보창의 **위치와 크기는 변하지 않는다**. 기존 노드 추적 팝업을 고정 도킹 패널로 대체한다. | `game.gd::INFO_PANEL_RECT / _resolve_info_context / tests::_check_tree_pan_and_popup` | 코드 일치·CI 통과 |
| 01:10 | 2. 기술트리(병종/건물 정의)와 우측 전장 개별 유닛이 **하나의 고정 정보창**을 공유한다. 누가 선택했는지만 콘텐츠가 바뀐다. | `game.gd::INFO_PANEL_RECT / _resolve_info_context / tests::_check_tree_pan_and_popup` | 코드 일치·CI 통과 |
| 01:11 | 3. 정보창은 전장, 헤더, 전투 버튼, 도움말, 대화창과 겹치지 않으며 패널 내부 스크롤로 긴 정보를 처리한다. | `game.gd::INFO_PANEL_RECT / _resolve_info_context / tests::_check_tree_pan_and_popup` | 코드 일치·CI 통과 |
| 01:12 | 4. 트리 20노드/19연결선, 선택 112%, 드래그 임계값 8px, 스킬트리 전체/기본 모드, PC/Web 공통 동작을 유지한다. | `game.gd::INFO_PANEL_RECT / _resolve_info_context / tests::_check_tree_pan_and_popup` | 코드 일치·CI 통과 |
| 01:15 | - 현재 `scripts/game.gd`: `POPUP_SIZE=(390,274)`, `_popup_rect()`가 노드 `_node_screen()` 위치를 따라 이동; 별도 `_upg… | `game.gd::_create_controls / tests::_check_tree_pan_and_popup` | 기존 코드 대비 변경 일치 |
| 01:16 | - `TreeClip`은 `Rect2(0,84,1376,892)`, 전장은 `Rect2(1376,84,544,652)`, 대화창은 `Rect2(28,778,1320,171)`. 기존 정보… | `game.gd::_create_controls / tests::_check_tree_pan_and_popup` | 기존 코드 대비 변경 일치 |
| 01:17 | - 변경 예상: `scripts/game.gd`의 정보창 레이어/Control 구성, 선택 처리·입력 판정·패닝 클램프, `tests/w52_ui_smoke.gd`의 정보창 및 포커스 계… | `game.gd::_create_controls / tests::_check_tree_pan_and_popup` | 기존 코드 대비 변경 일치 |
| 01:22 | \| 패널 외곽 \| `Rect2(930,170,420,560)` \| 좌측 트리 내부, 오른쪽 끝 26px 여백, 하단 730px \| | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:23 | \| 상단 제목/상태 \| 높이 약 80px \| 스크롤해도 제목·상태 확인 가능 \| | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:24 | \| 중간 내용 \| 세로 스크롤 \| 3개 선행 조건, A/B 강화 및 능력치까지 오버플로 허용 \| | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:25 | \| 하단 액션 \| 높이 약 66~80px \| 스크롤과 독립 고정, 버튼은 04 문서의 상태 규칙 사용 \| | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:26 | \| 전장 \| x>=1376 \| 패널이나 버튼이 침범하지 않음 \| | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:27 | \| 대화 레이어 \| y>=778 \| 패널 하단 730px으로 독립 \| | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:28 | - 위 수치는 최종 미술 수치가 아니다. **고정 위치·비겹침·액션 가시성**이 불변 조건이며 구현 중 폰트/스크롤 실측으로 조정한다. | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 실제 폰트/스크롤 픽셀 측정 미검증 |
| 01:29 | - 창의 닫기/비선택 처리는 02·04의 선택 복귀 규칙을 따른다. 기본은 패널을 항상 표시하며, 선택 컨텍스트가 없으면 HQ를 기본 컨텍스트로 사용한다. | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:30 | - 24개 A/B 강화는 트리 아이콘/선으로 추가하지 않는다. 현재의 별도 떠다니는 강화 카드 대신 **고정 정보창의 유닛 상세 섹션**으로 통합한다(03에서 내용 정의). | `game.gd::_create_controls / _draw_info_frame / _render_info_content` | 코드 일치·CI 통과; 화면 픽셀 QA 별도 |
| 01:33 | - 정보창 전체는 클릭·휠·드래그 시작을 **트리 패닝보다 우선 소비**한다. 정보창 내부 스크롤을 트리 이동으로 오인하지 않는다. 버튼 입력은 해당 Button 신호로 처리한다. | `game.gd::_gui_input / _node_at / _readable_tree_area / _clamp_pan` | 코드 일치·CI 통과; 실제 마우스 QA 별도 |
| 01:34 | - `_popup_rect()`의 노드 상대 위치 계산을 제거하고 `_info_panel_rect()` 같은 단일 고정 사각형을 도입한다. 실제 Control 위치/크기와 입력 판정은 그… | `game.gd::_gui_input / _node_at / _readable_tree_area / _clamp_pan` | 코드 일치·CI 통과; 실제 마우스 QA 별도 |
| 01:35 | - 선택 노드 포커스의 기존 목표 화면 좌표 (688,530)는 유지한다. 패널이 항상 x930부터 시작하므로 중앙 포커스 시 선택 노드 아이콘과 라벨이 가려지지 않는지 검증한다. | `game.gd::_gui_input / _node_at / _readable_tree_area / _clamp_pan` | 코드 일치·CI 통과; 실제 마우스 QA 별도 |
| 01:36 | - 기존 `_readable_tree_area()`/`_clamp_pan()`는 패널 아래 보이지 않는 노드만으로 '완전한 노드 하나 가시'를 충족했다고 오판할 수 있다. **패널을 제외… | `game.gd::_gui_input / _node_at / _readable_tree_area / _clamp_pan` | 코드 일치·CI 통과; 실제 마우스 QA 별도 |
| 01:37 | - 기본 트리/전체 기술도 전환과 전장 선택에 따른 노드 강조는 패널 좌표를 바꾸지 않는다. | `game.gd::_gui_input / _node_at / _readable_tree_area / _clamp_pan` | 코드 일치·CI 통과; 실제 마우스 QA 별도 |
| 01:38 | - 화면 스트레치 및 1280×720 실제 창 크기에서 CanvasItem 논리 좌표와 입력 좌표계의 일치를 확인한다. PC/Web 분기 UI를 만들지 않는다. | `game.gd::_gui_input / _node_at / _readable_tree_area / _clamp_pan` | PC/Web 실제 입력 좌표는 브라우저 QA 미검증 |
| 01:41 | 1. `InfoPanel` 또는 기존 `NodeInfoLayer`를 고정 Control로 전환하고, 제목/스크롤/버튼 영역을 구조적으로 분리한다. | `game.gd::_refresh_info_panel / _resolve_info_context / _render_info_content` | 구현 일치 |
| 01:42 | 2. 기존 `_draw_popup`와 `_draw_upgrade_panel`의 역할을 03의 공통 렌더/갱신 구조로 옮긴다. 중복 패널이 남지 않게 한다. | `game.gd::_refresh_info_panel / _resolve_info_context / _render_info_content` | 구현 일치 |
| 01:43 | 3. 정보창 입력 차단과 TreeClip 패닝·선택 우선순위를 맞춘다. | `game.gd::_refresh_info_panel / _resolve_info_context / _render_info_content` | 구현 일치 |
| 01:44 | 4. 고정 정보창을 제외한 가시 노드 검사와 포커스 경계를 업데이트한다. | `game.gd::_refresh_info_panel / _resolve_info_context / _render_info_content` | 구현 일치 |
| 01:45 | 5. 02~05의 선택·데이터·버튼 연결을 동일 패널에 적용한다. | `game.gd::_refresh_info_panel / _resolve_info_context / _render_info_content` | 구현 일치 |
| 01:48 | - 처음 HQ 선택, 20개 각 노드 선택, 전장 개체 선택, 8px 클릭/드래그, 카메라 보간 12프레임, 49개 팬 지점에서도 정보창 좌표가 불변. | `tests::_check_tree_pan_and_popup / _check_main_entry; Actions 41800013533` | 헤드리스·Web Export 통과; 화면 QA 별도 |
| 01:49 | - 3개 선행 조건과 A/B 강화가 포함되어도 글자/버튼이 패널을 벗어나지 않음; 실제 폰트 측정. | `tests::_check_tree_pan_and_popup / _check_main_entry; Actions 41800013533` | 실제 폰트 오버플로 픽셀 검증 미실시 |
| 01:50 | - 전장·대화·헤더·도움말 비겹침; 클릭·스크롤·드래그 입력 분리; 패널 아래 노드를 '가시'로 오판하지 않음. | `tests::_check_tree_pan_and_popup / _check_main_entry; Actions 41800013533` | 실제 마우스/휠 QA 미실시 |
| 01:51 | - 헤드리스 씬/저장 호환성/웹 Export는 기능 브랜치에서 검사하고, 실제 웹 픽셀·포인터 QA는 별도로 미검증 표시. | `tests::_check_tree_pan_and_popup / _check_main_entry; Actions 41800013533` | 헤드리스 및 Export PASS, 브라우저 픽셀 QA 미검증 |
| 01:52 | - 구형 정보창의 좌표 고정 테스트(`_popup_rect`, `_upgrade_rect`, `POPUP_BUTTON_OFFSET`)는 새 고정 패널 계약으로 대체한다. | `tests::_check_tree_pan_and_popup / _check_main_entry; Actions 41800013533` | 헤드리스·Web Export 통과; 화면 QA 별도 |
| 01:55 | - 정식 능력치, 가격·결제, 강화 구매, 전투 이동 정책은 본 문서에서 확정하지 않는다. | `game.gd::UPGRADES / 미실행 정책 함수 / 단일 게임 씬` | 정책 유보 준수 |
| 01:56 | - 새 별도 상세 화면이나 독립된 웹 전용 패널을 추가하지 않는다. | `game.gd::UPGRADES / 미실행 정책 함수 / 단일 게임 씬` | 정책 유보 준수 |
| 01:57 | - 기존 게임 노드/선/구매 규칙과 저장을 단순 레이아웃 수정만으로 변경하지 않는다. | `game.gd::UPGRADES / 미실행 정책 함수 / 단일 게임 씬` | 정책 유보 준수 |

### W52_02: W52_02_INITIAL_HQ_SELECTION_IMPLEMENTATION_DESIGN_2026-11-04.md

| 원문 행 | 내용 요지 | 코드·검증 근거 | 판정 |
|---|---|---|---|
| 02:3 | - 문서 상태: **구현 지시용 상세 설계**, 코드 미구현. | `설계 기준 메타` | 설계 시점 설명 |
| 02:4 | - 기준: `AGENTS.md` 및 01 고정 정보창, 03 정보 요소, 05 전장 선택. `main` 3a85347295377557a7b2c57d539206c4f1d01518. | `설계 기준 메타` | 설계 시점 설명 |
| 02:5 | - 변경 대상: `scripts/game.gd`, `tests/w52_ui_smoke.gd`. 저장 스키마 확장은 이 기능만으로 요구하지 않는다. | `설계 기준 메타` | 설계 시점 설명 |
| 02:8 | 1. 새 게임으로 게임 씬에 처음 진입하면 **HQ 노드가 이미 선택**된 상태이고 고정 정보창에 HQ 설명이 나온다. 플레이어의 첫 클릭이 필요하지 않다. | `game.gd::_ready / _set_week_intro / restore_state / _select_node` | 코드 일치·CI 통과 |
| 02:9 | 2. 선택 상태·카메라·정보창이 동기화되어 HQ가 대화 레이어에 가려지지 않는다. | `game.gd::_ready / _set_week_intro / restore_state / _select_node` | 코드 일치·CI 통과 |
| 02:10 | 3. 복구된 게임도 저장 당시의 '선택 개체'가 기록되지 않은 현재 데이터 계약에서는 **HQ를 안전한 기본 선택**으로 사용한다. | `game.gd::_ready / _set_week_intro / restore_state / _select_node` | 코드 일치·CI 통과 |
| 02:11 | 4. 트리·우측 전장 선택을 시작하면 HQ 선택에서 자연스럽게 전환하고, 다른 사용자 선택을 매 프레임 강제로 HQ로 되돌리지 않는다. | `game.gd::_ready / _set_week_intro / restore_state / _select_node` | 코드 일치·CI 통과 |
| 02:14 | - 현재 `_ready() → _set_week_intro()`는 `selected_id=""`; `restore_state()`도 `selected_id=""`; 이 때문에 처음 정보창… | `game.gd::_set_week_intro / restore_state / _refresh_all` | 코드 일치·CI 통과 |
| 02:15 | - `_set_week_intro()`, `restore_state()`에서 데이터/주차와 보유 시설을 완성한 뒤 `selected_id="hq"` 또는 공통 `_select_initia… | `game.gd::_set_week_intro / restore_state / _refresh_all` | 코드 일치·CI 통과 |
| 02:16 | - 이미 코드에 있는 `camera_offset = _clamp_pan(TREE_CENTER_LOCAL - hq.p)`는 유지한다. 새 패널의 고정 위치는 선택 위치에 영향을 주지 않는다… | `game.gd::_set_week_intro / restore_state / _refresh_all` | 코드 일치·CI 통과 |
| 02:17 | - 렌더/버튼 반영 시 `_refresh_all()` 및 고정 정보창 갱신이 빠지지 않게 한다. | `game.gd::_set_week_intro / restore_state / _refresh_all` | 코드 일치·CI 통과 |
| 02:18 | - HQ는 기본 소유(`owned_buildings`에 반드시 포함). HQ에는 건설/배치 버튼을 표시하지 않는다. | `game.gd::_set_week_intro / restore_state / _refresh_all` | 코드 일치·CI 통과 |
| 02:23 | \| 새 게임 진입 / W01 첫 프레임 \| HQ 선택 \| HQ 보유/시작 경로 \| HQ를 읽을 수 있게 중앙 포커스 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:24 | \| v2/v3 세이브 이어하기 \| 선택 ID 미저장이므로 HQ 선택 \| 현재 주차 기준 HQ 정보 \| HQ 포커스 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:25 | \| 다음 주 진입 \| 이전 주 배치 제거 후 HQ로 복귀(현행 선택 초기화의 빈값 대체) \| HQ 정보 \| HQ 포커스 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:26 | \| 기술트리의 다른 노드 클릭 \| 해당 노드 우선 \| 해당 노드 정보 \| 선택 노드 포커스 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:27 | \| 전장의 기존 유닛 클릭 \| 해당 개별 유닛 우선 \| 개체 정보, 연결 병종 \| 필요 시 해당 병종 포커스 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:28 | \| 전장의 빈 칸 클릭 \| 개별 유닛 선택 해제, 마지막 트리 선택(HQ 기본) 복귀 \| 트리 선택 정보 \| 임의로 HQ 강제 포커스하지 않음 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:29 | \| 선택 없이 시작할 수 있는 전투·결과 단계 \| HQ 포함 마지막 트리 선택 유지 \| 읽기 전용으로 갱신 \| 카메라 강제 이동 없음 \| | `game.gd::_select_node / _select_field_instance / _return_to_tree_context / _battle_action` | 코드 일치·CI 통과 |
| 02:32 | - 현재 `_advance_dialogue()`는 W01 세 번째 진행에서 `_select_node("rifle")`을 실행한다. 이는 기초 유닛 배치 튜토리얼 동선이다. | `game.gd::_advance_dialogue / user_selected_context` | 코드 일치·CI 통과 |
| 02:33 | - 시작 프레임 HQ 선택을 보장하면서 **사용자가 이미 다른 노드/개체를 직접 선택했다면 튜토리얼의 소총병 자동 선택이 덮어쓰지 않도록** 구분한다. 아무 사용자 입력 없이 HQ 기본 … | `game.gd::_advance_dialogue / user_selected_context` | 코드 일치·CI 통과 |
| 02:34 | - 자동 선택은 **W01 튜토리얼로 한정**한다. 현재 코드가 다른 주에서도 수행할 수 있으므로 코드/대사 정합성 검사 후 수정한다. | `game.gd::_advance_dialogue / user_selected_context` | 코드 일치·CI 통과 |
| 02:35 | - 명시되지 않은 추가 자동 선택, 구매, 배치를 만들지 않는다. | `game.gd::_advance_dialogue / user_selected_context` | 코드 일치·CI 통과 |
| 02:38 | - `selected_tree_node_id`는 건물/병종 ID, `selected_instance_id`는 전장 개체 ID(05), `selection_origin`은 `tree`/`b… | `game.gd::selected_id / selected_instance_id; main.gd::_pause_game` | 코드 일치, 실제 ESC·브라우저 QA 미검증 |
| 02:39 | - 고정 정보창이 '닫힌다'는 개념 대신 다른 노드/개체로 **내용이 교체**된다. 전장 선택 해제 시 마지막 트리 선택을 보여 준다. 선택 무효 데이터는 HQ로 폴백한다. | `game.gd::selected_id / selected_instance_id; main.gd::_pause_game` | 코드 일치, 실제 ESC·브라우저 QA 미검증 |
| 02:40 | - 일시정지/메뉴에서는 현재 입력을 차단한다. 복귀 시 선택 상태가 유효하면 유지한다. | `game.gd::selected_id / selected_instance_id; main.gd::_pause_game` | 정적 일치, 실제 ESC/일시정지 수동 검증 필요 |
| 02:43 | - 메인 씬 실제 경로 `main.tscn → title → main menu → new game`에서 처음 게임 프레임의 HQ 선택·노드 강조·정보창 제목 확인. | `tests::_check_integrated_tree / _check_main_entry / _check_field_placement` | 헤드리스 통과; 실제 브라우저 QA 별도 |
| 02:44 | - 모든 시작/복구/다음 주 경로에서 HQ 디폴트; 대화의 자동 소총병 선택이 **이미 한 사용자 선택을 덮어쓰지 않음**; W02 이상 불필요한 자동 소총병 선택 없음. | `tests::_check_integrated_tree / _check_main_entry / _check_field_placement` | 헤드리스 통과; 실제 브라우저 QA 별도 |
| 02:45 | - HQ가 대화창 아래에 묻히지 않음. 선택 전환 후 정보창은 01의 고정 좌표 유지. | `tests::_check_integrated_tree / _check_main_entry / _check_field_placement` | HQ 도킹 좌표 CI 대조, 실제 픽셀 QA 미검증 |
| 02:46 | - v2/v3 저장 불러오기와 신규 저장 후 이어하기 회귀. 현재 버전에 선택 ID를 무리하게 추가하지 않음. | `tests::_check_integrated_tree / _check_main_entry / _check_field_placement` | 헤드리스 통과; 실제 브라우저 QA 별도 |
| 02:47 | - 실제 브라우저 픽셀 QA는 별도. 구현 설계 대조 결과를 문서/감사 기록에 남긴다. | `tests::_check_integrated_tree / _check_main_entry / _check_field_placement` | 브라우저 픽셀 QA 미검증 |
| 02:50 | - 01의 고정 패널과 03의 HQ 콘텐츠 렌더가 먼저 또는 함께 구현되어야 첫 프레임의 정보창을 확인할 수 있다. | `game.gd::_resolve_info_context / _get_info_actions` | 코드 일치 |
| 02:51 | - 04의 버튼 상태 평가에서 `hq`는 '보유/조회' 전용이며, 05에서 전장 개체 선택과 HQ 기본 선택 간 전환을 정의한다. | `game.gd::_resolve_info_context / _get_info_actions` | 코드 일치 |

### W52_03: W52_03_NODE_INFO_CONTENT_IMPLEMENTATION_DESIGN_2026-11-04.md

| 원문 행 | 내용 요지 | 코드·검증 근거 | 판정 |
|---|---|---|---|
| 03:3 | - 상태: **구현 지시용 상세 설계**. 데이터 미확정 항목은 빈 숫자를 꾸며내지 않고 '미정/미구현'으로 노출한다. 코드 변경 없음. | `설계 원본 기준 / game.gd::NODES / UPGRADES` | 정적 일치 |
| 03:4 | - 적용 범위: `scripts/game.gd`, 필요한 경우 작은 UI 데이터 매핑, 01 고정 패널에 결합. `main` 3a85347295377557a7b2c57d539206c4f1… | `설계 원본 기준 / game.gd::NODES / UPGRADES` | 정적 일치 |
| 03:5 | - 기준: `AGENTS.md`, 현행 `NODES`(20개), `UPGRADES`(24개), 관련 기술트리 설계. | `설계 원본 기준 / game.gd::NODES / UPGRADES` | 정적 일치 |
| 03:6 | - **구별:** 확정된 모델 구조(종류/선행 시설) / 현재 시연 주차(후보) / 미확정 전투 수치 및 가격. '기본 효과'는 실제 전투 적용을 보증하지 않는다. | `설계 원본 기준 / game.gd::NODES / UPGRADES` | 정적 일치 |
| 03:9 | 패널 전체는 01의 동일 고정 위치를 사용. 한 순간에 활성 컨텍스트는 하나: | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:10 | - `TREE_BUILDING`: HQ/생산/기술시설 선택 → 이름·시설 효과·보유/해금/건설 상태. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:11 | - `TREE_UNIT`: 트리에서 병종 노드 선택 → 이름·기본 역할·주차·필요 시설·기본 병종 능력치(정의된 경우)·A/B 고유 강화 조회. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:12 | - `FIELD_INSTANCE`: 우측 전장에서 배치된 특정 개체 선택 → 이름+개체 식별·현재/최대 HP(정의된 경우)·사거리(정의된 경우)·현재 위치/배치 상태·기본 병종 역할·A/… | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:14 | 공통 화면 계층 (길면 내용 영역만 세로 스크롤): | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:15 | 1. 제목: 이름, 유형(본부/생산시설/기술시설/유닛), 현재 상태. 미래 해금 주차에는 '후보' 명시. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:16 | 2. 역할 설명: 플레이어 의사결정에 필요한 1~2문장. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:17 | 3. 해금/보유: 최소 Wxx vs 현재 Wxx, 선행 시설 명단 각자의 `보유/미보유`; 3개 이상도 줄 바꿈. 생산시설 보유와 해당 유닛 배치 가능을 구분. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 스크롤 구현, 3개 조건 폰트 실측 미검증 |
| 03:18 | 4. 병종 관련 정보: 건물의 경우 생산·해금에 기여하는 병종; 유닛의 경우 전투 역할·능력치·고유 강화. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:19 | 5. 하단 버튼: 04의 노출/활성 규칙. 비활성 이유는 짧은 문구로 설명. | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:21 | 불변 조건: 숫자 데이터가 없다면 `0`, `100`, `3칸` 등의 가상 값을 표시하지 않는다. 비활성 기능은 실제 가능한 기능처럼 보이게 하지 않는다. 노드 IDs, 수치, 상태는 `… | `game.gd::_resolve_info_context / _refresh_info_panel / _render_info_content` | 코드 일치·CI 통과; 실제 글꼴 QA 별도 |
| 03:26 | \| 본부(HQ) W01 \| 시작 뿌리, 보유 상태, 전체 트리의 출발점 \| 직계: 로봇 공장, 워커 공장, 레이더 기지, 동력로 \| 건설/배치 없음 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:27 | \| 로봇 공장 W01 \| 로봇 5종 생산 \| 소총병, 기관총병, 박격포, 대전차병, 야포; 연결 기술시설 무기고 \| 보유 시 관련 병종 보기 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:28 | \| 워커 공장 W09 \| 워커 4종 생산 \| 장갑차, 전차, 구축전차, 중전차; 연결 기술시설 기계 공작소 \| 미보유 시 시연 건설 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:29 | \| 드론 격납고 W15 \| 드론 3종 생산 \| 전투기, 공격기, 폭격기; 부모 레이더 기지 \| 미보유 시 시연 건설 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:30 | \| 무기고 W10 \| 무장/로켓/포격 기술 \| 직접 추가 조건: 대전차병, 야포, 공격기 \| 미보유 시 시연 건설 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:31 | \| 레이더 기지 W15 \| 드론 관제·정밀 조준 \| 직접 추가 조건: 야포, 구축전차; 건물 해금: 드론 격납고(항공 3종 간접) \| 미보유 시 시연 건설 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:32 | \| 기계 공작소 W18 \| 고급 차체·워커 플랫폼 \| 직접 추가 조건: 전차, 구축전차, 중전차 \| 미보유 시 시연 건설 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:33 | \| 동력로 W32 \| 고출력 동력 \| 직접 추가 조건: 중전차, 폭격기 \| 미보유 시 시연 건설 \| | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:35 | - 생산/기술시설에 공통: 부모 이름/보유 상태, 최소 후보 주차, `보유` 또는 `조건 충족/잠금`, '즉시 완공·건설 비용 미정(시연)'. | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:36 | - **연계 대상 표시 ≠ 지금 생산 가능.** 각 병종의 독립 주차/다른 선행 시설 조건을 표시하거나 상세 선택 시 다시 평가한다. | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:37 | - 본부는 기본 보유라서 건설 버튼을 그리지 않는다. 로봇 공장도 기본 보유. | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:38 | - 시설의 보유는 영구적이고 유닛의 전장 배치는 매주 초기화된다. 시설에서 병종이 열리는 것을 '유닛 보유'로 표시하지 않는다. | `game.gd::NODES / _related_unit_ids / _render_info_content / _get_info_actions` | 코드 일치·CI 액션 검사 통과 |
| 03:41 | 각 줄의 주차는 **현행 시연 후보**이며 확정 경제 수치가 아님. | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:45 | \| `rifle` 소총병 \| 01 \| 로봇 공장 \| 저비용 범용 사격·기본 대공 보조 \| 고속 장전(연사 개선) / 대공 추적(공중 대응 개선) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:46 | \| `mg` 기관총병 \| 02 \| 로봇 공장 \| 연사와 경량 표적 처리 \| 연사 강화(지속 화력) / 표적 전환(경량 다수 대응) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:47 | \| `mortar` 박격포 \| 04 \| 로봇 공장 \| 저비용 간접포격 \| 확산 포탄(광역 지원) / 자동 장전(발사 속도) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:48 | \| `anti_tank` 대전차병 \| 10 \| 로봇 공장+무기고 \| 저비용 대장갑 특화 \| 관통탄(장갑 피해) / 유도 조준(표적 추적) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:49 | \| `artillery` 야포 \| 21 \| 로봇 공장+무기고+레이더 기지 \| 장거리 후열 화력 \| 장포신(사거리) / 고폭 포탄(포격 범위) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:50 | \| `car` 장갑차 \| 09 \| 워커 공장 \| 경량 워커 전열·빠른 연사 \| 추가 장갑(생존력) / 속사 포탑(경량 표적 대응) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:51 | \| `tank` 전차 \| 18 \| 워커 공장+기계 공작소 \| 범용 장갑 전열 \| 복합 장갑(생존력) / 고폭탄(소형 광역) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:52 | \| `destroyer` 구축전차 \| 29 \| 워커 공장+기계 공작소+레이더 기지 \| 단일 대전차 플랫폼 \| 관통 포탄(대장갑 화력) / 정밀 조준(표적 추적) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:53 | \| `heavy` 중전차 \| 36 \| 워커 공장+기계 공작소+동력로 \| 고내구 전열 \| 강화 장갑(생존력) / 중포탄(일격 피해) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:54 | \| `fighter` 전투기 \| 15 \| 드론 격납고 \| 공중 요격 \| 요격 레이더(공중 탐지) / 속사 기관포(연사) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:55 | \| `attacker` 공격기 \| 24 \| 드론 격납고+무기고 \| 지상 지원·범위 공격 \| 확산 로켓(광역) / 정밀 유도탄(장갑 대응) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:56 | \| `bomber` 폭격기 \| 40 \| 드론 격납고+동력로 \| 대규모 폭격 \| 확산 폭탄(타격 범위) / 중량 폭탄(일격 피해) \| | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:58 | - 전투기는 `drone_hangar`를 통해 레이더 기지를 **간접** 선행으로 요구한다. 간접 부모 체인과 직접 추가 요구를 혼동하지 않는다. | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:59 | - A/B는 12종×2=24개, **트리 내부에는 미표시**. 이름과 역할 제안만 보여주고 구매/보유·실효 숫자·가격은 정책 확정 전 표시하지 않는다. | `game.gd::NODES / UPGRADES / _render_info_content` | 정적 원본 12종·24강화 일치 |
| 03:64 | \| HP \| 정의된 **기본 최대 HP** \| 현재 HP / 최대 HP \| 'HP: 미구현' \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:65 | \| 사거리 \| 정의된 기본 사거리, 단위 표기 \| 적용 중인 사거리 \| '사거리: 미정' \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:66 | \| 공격력/공격주기 \| 기본 정의 있을 때 \| 실효 수치가 계산 가능할 때 \| 해당 숫자 대신 '미정' \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:67 | \| 방어/표적 유형 \| 전투 모델이 제공할 때 \| 개별 상태가 있으면 적용 값 \| 숨기거나 '미정' \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:68 | \| 개체 식별자 \| 표시하지 않음 \| 병종 이름 + 구분용 순번/ID \| 생성된 `instance_id` 사용 \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:69 | \| 전장 위치 \| 표시하지 않음 \| `grid_cell` 기반 행/열 \| 위치가 없으면 표시하지 않음 \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:70 | \| 현재 배치 수 \| 병종별 수 / 전체 12칸 \| 동일 병종 수 / 전체 12칸 \| 배치 데이터에서 산출 \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:71 | \| 강화 A/B \| 조회 전용 \| 조회 전용 \| 가격·구매 상태 미표시 \| | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:73 | - 현재 W52의 전투는 타이머 기반 시연이며 실제 HP·사거리·공격력 자료가 없다. 구현 단계에서 가상 밸런스 값을 `game.gd`에 삽입하지 않는다. | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:74 | - 숫자 표시용 함수는 실제 전투 데이터가 연결될 때만 유효 값을 제공한다. `current HP`는 전장 개체만 갖는 동적 값; `max HP`·사거리 등 기본 능력치는 병종 자료가 소… | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 코드 일치, 미승인 수치 유보 |
| 03:75 | - HP 수치가 도입되면 0~max 범위 검증, max<=0 방어, 표기/막대 동기화 필요. 사거리 단위와 거리 판정(원형/격자 등)은 미정이므로 'N칸'을 가정해 공격범위를 그리지 않는… | `game.gd::_unit_count / _render_info_content / FIELD_INSTANCE / save_manager.gd` | 미도입 수치 정책: 현재 적용 대상 없음 |
| 03:78 | - W01 HQ: `본부 · 보유`, 역할, 직계 4시설, 구매 버튼 없음. | `game.gd::_get_info_actions / _select_field_instance / _build_selected` | 코드 일치·CI 통과 |
| 03:79 | - W18 기계 공작소 미보유·워커 공장 보유: 주차 조건 및 부모 보유에 따라 `시연 건설` 가능. 다른 관련 병종은 현행 각자 조건을 적용. | `game.gd::_get_info_actions / _select_field_instance / _build_selected` | 코드 일치·CI 통과 |
| 03:80 | - W29 구축전차, 레이더 기지 미보유: `배치 잠금`, 3개 필수 시설 중 레이더 기지만 미보유로 표시, `필요 시설 찾기`. | `game.gd::_get_info_actions / _select_field_instance / _build_selected` | 코드 일치·CI 통과 |
| 03:81 | - 전장 소총병 #03: 위 내용은 병종과 공유하지만 `현재 개체의 위치/HP(실제 데이터만)`와 `배치 취소` 버튼은 추가로 보여 준다. | `game.gd::_get_info_actions / _select_field_instance / _build_selected` | 코드 일치·CI 통과 |
| 03:82 | - 전투/결과 단계: 기존 데이터 조회는 되지만 건설·배치·배치 취소는 비활성/숨김. | `game.gd::_get_info_actions / _select_field_instance / _build_selected` | 코드 일치·CI 통과 |
| 03:85 | 1. `NODES`/`UPGRADES`를 단일 소스로 사용해 타입별 요약 모델/공통 정보창 데이터 구성. 별도 복제된 게임 규칙 테이블은 생성하지 않는다. | `tests::_check_integrated_tree / _check_action_matrix / _check_field_placement` | 헤드리스·Web Export 통과, 시각 QA 별도 |
| 03:86 | 2. `buildings`, `week`, `phase`, `placements`로 실제 상태 평가. 버튼 활성은 04, 개체 ID/위치는 05에 위임. | `tests::_check_integrated_tree / _check_action_matrix / _check_field_placement` | 헤드리스·Web Export 통과, 시각 QA 별도 |
| 03:87 | 3. 20노드의 이름·주차·필수 시설·역할, 강화 24항목을 원본과 정적 대조. 3개 요구 시설 줄 바꿈·스크롤·마지막 버튼 가시성 검증. | `tests::_check_integrated_tree / _check_action_matrix / _check_field_placement` | 노드/강화 정적 일치, 실제 렌더 글꼴 실측 미검증 |
| 03:88 | 4. 결측 수치 미표시/미정, 개별 HP와 병종의 최대 HP 혼동 없음, 전투 조회 전용, 전체/기본 트리 및 저장 복구 회귀 검증. | `tests::_check_integrated_tree / _check_action_matrix / _check_field_placement` | 헤드리스·Web Export 통과, 시각 QA 별도 |
| 03:89 | 5. 시연 수치와 미승인 정책은 확정 사실로 UI에 쓰지 않는다. 불일치가 있으면 설계-코드 대조 → 수정 → 재검사를 문서에 기록한다. | `tests::_check_integrated_tree / _check_action_matrix / _check_field_placement` | 헤드리스·Web Export 통과, 시각 QA 별도 |
| 03:92 | - 01 고정 패널, 02 기본 HQ, 04 버튼, 05 개별 인스턴스 데이터와 연결되어야 최종 UI 검증 가능. | `game.gd::INFO_PANEL_RECT / _request_range_overlay` | 정책 유보 준수 |
| 03:93 | - 공식 전투 스탯 및 사거리 판정은 별도 승인/검증 전까지 조회 자리만 확보한다. 가짜 HP 숫자, 영구 유닛 소유, 강화 구매를 추가하지 않는다. | `game.gd::INFO_PANEL_RECT / _request_range_overlay` | 정책 유보 준수 |

### W52_04: W52_04_INFO_PANEL_ACTIONS_IMPLEMENTATION_DESIGN_2026-11-04.md

| 원문 행 | 내용 요지 | 코드·검증 근거 | 판정 |
|---|---|---|---|
| 04:3 | - 상태: **구현 지시용 상세 설계**. 코드 미구현. | `설계 목적·범위 / game.gd::_get_info_actions` | 코드 일치 |
| 04:4 | - 기준: `AGENTS.md`, `main` 3a85347295377557a7b2c57d539206c4f1d01518, 01~03·05 문서. | `설계 목적·범위 / game.gd::_get_info_actions` | 코드 일치 |
| 04:5 | - 원칙: **버튼 1회 입력은 의미 있는 결과 또는 명시적 거부 사유를 가진다.** 구현할 수 없는 게임 규칙은 임의 구현하지 않고 함수 계약만 두며, 해당 버튼은 비활성/미노출 처리한… | `설계 목적·범위 / game.gd::_get_info_actions` | 코드 일치 |
| 04:6 | - 기능 범위: 하나의 고정 정보창의 하단 **주 행동 최대 1개, 문맥 보조 동작 0~1개**를 기본으로 하되 상세의 관련 유닛 링크/선행 시설 링크는 콘텐츠 영역에서 선택 가능. 불필… | `설계 목적·범위 / game.gd::_get_info_actions` | 코드 일치 |
| 04:9 | - 현재 `scripts/game.gd`: `deploy_button.pressed → _action_selected()` → 종류에 따라 `_build_selected()` 또는 `_d… | `game.gd::_action_selected / _on_info_primary_action / _build_selected` | 코드 일치·CI 통과 |
| 04:10 | - 건설은 `phase in ["dialogue","prepare"]`, 부모 보유·최소 주차를 만족할 때만 즉시 소유 배열에 추가한다. 비용은 미확정이므로 G 차감 없음. | `game.gd::_action_selected / _on_info_primary_action / _build_selected` | 코드 일치·CI 통과 |
| 04:11 | - 배치는 `phase in ["dialogue","prepare"]`·필수 시설/최소 주차·12개 슬롯을 검사한 뒤 배치 종류 ID를 추가한다. 현행은 위치 자동 결정이며 05에서 **… | `game.gd::_action_selected / _on_info_primary_action / _build_selected` | 코드 일치·CI 통과 |
| 04:12 | - `_action_selected()`와 단일 `deploy_button`의 책임을 '행동 정책 평가 → 안전한 수행'으로 명확히 재구성한다. 기존 `_build_selected()`,… | `game.gd::_action_selected / _on_info_primary_action / _build_selected` | 코드 일치·CI 통과 |
| 04:17 | \| HQ 기본 보유 \| 없음 \| 직계 시설 링크 \| 시설 선택/포커스 \| HQ 구매·배치 없음 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:18 | \| 생산/기술시설 미보유·조건 충족·준비 가능 \| `시연 건설` \| 관련 병종 보기 \| 즉시 보유 처리, 요건·트리·정보창 새로고침 \| 0G 확정 가격 아님 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:19 | \| 생산/기술시설 미보유·조건 부족 \| `건설 불가` 비활성 \| `선행 시설 찾기` 또는 관련 요건 링크 \| 미충족 시설 선택, 필요 시 전체 기술도 표시 \| '주차 부족'만이면… | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:20 | \| 생산/기술시설 이미 보유 \| 건설 버튼 없음 \| `관련 병종 보기` \| 실제 연계 병종 이름 목록/노드 선택 \| 병종 조건과 구매를 혼동하지 않음 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:21 | \| 트리 유닛·주차/시설 충족·12칸 미만·준비 가능 \| `배치` \| 필요 시 강화 조회(동일 패널) \| 05의 **신규 유닛 위치 지정 대기** 진입 \| 클릭만으로 자동 생성하… | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:22 | \| 트리 유닛·잠금 \| `배치 불가` 비활성 \| `필요 시설 찾기` \| 부족한 건물 노드로 이동 \| 필수 시설 각각 체크리스트 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:23 | \| 트리 유닛·총 12칸 사용 \| `배치 불가` 비활성 \| 불가 원인 표시 \| 상태 변경 없음 \| 버튼 누른 뒤 로그로만 안내하지 않음 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:24 | \| 전장 개체 선택·준비 가능 \| `배치 취소` \| 필요 시 `트리 병종 보기` 링크 \| 그 **개체 1기**만 제거; 전장/정보창 갱신 \| 병종/건물 보유는 유지 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:25 | \| 전장 개체 선택·전투/결과 \| 없음(조회 전용) \| 트리 병종 링크 \| 조회만 가능 \| 이동/배치취소 금지 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:26 | \| 새 유닛 위치 지정 대기 \| `위치 지정 취소` \| 없음 \| 위치 선택 모드만 취소, 유닛 미생성 \| `배치 취소`(기존 개체 제거)와 구분 \| | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:28 | **우측 기존 유닛 단순 클릭 = 개체 선택 + 배치 편집 가능한 컨텍스트**, 별도 '이동 버튼'이나 '수정 모드 버튼'은 만들지 않는다. 유닛 드래그가 곧 위치 변경(05). | `game.gd::_get_info_actions / _on_info_secondary_action / _begin_new_unit_placement / _remove_placed_instance` | 코드 일치·CI 액션 매트릭스 통과 |
| 04:31 | - 활성 조건은 버튼 렌더뿐 아니라 실제 핸들러에서도 **재검사**(노드·개체 존재, 주차, 단계, 부모·추가 시설, 보유, 슬롯, 셀 점유, 대상 유효성). | `game.gd::_get_info_actions / _on_info_primary_action / _confirm_pending_at` | 코드 일치·CI 통과 |
| 04:32 | - 동일 버튼 중복 클릭: 이미 보유 건물 재구매 없음, 12칸 초과 없음, 배치 대기 중 `배치` 재누름으로 중복 유닛 생성 없음. | `game.gd::_get_info_actions / _on_info_primary_action / _confirm_pending_at` | 코드 일치·CI 통과 |
| 04:33 | - 클릭 직후 동기적으로 모델 갱신 → 노드/경로, 해당 정보창, 배치 상태, 로그 순으로 refresh. 스크롤 및 선택 전환은 사용자가 명시한 경우에만 이동한다. | `game.gd::_get_info_actions / _on_info_primary_action / _confirm_pending_at` | 코드 일치·CI 통과 |
| 04:34 | - 실패 시 원인을 정보창 또는 기존 로그에 짧게 제공하되 상태는 그대로 유지. 정책 미정인 행동은 사용 가능한 버튼으로 보이지 않게 한다. | `game.gd::_get_info_actions / _on_info_primary_action / _confirm_pending_at` | 코드 일치·CI 통과 |
| 04:35 | - `시연 건설`은 비용 확정이 아니며 현행 무료 즉시 처리 유지, 건설 환불은 불가. | `game.gd::_get_info_actions / _on_info_primary_action / _confirm_pending_at` | 코드 일치·CI 통과 |
| 04:36 | - 실제 배치 제거는 준비 단계에서만. 이번 시연은 무료 배치이므로 금전 환급 또는 보유권 취소를 처리하지 않는다. | `game.gd::_get_info_actions / _on_info_primary_action / _confirm_pending_at` | 코드 일치·CI 통과 |
| 04:39 | **실행 기능(기존 함수를 재사용하고 필요한 연결만 구현):** | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:40 | - `_resolve_info_context()` → `TREE_BUILDING \| TREE_UNIT \| FIELD_INSTANCE`와 유효 ID 반환. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:41 | - `_get_info_actions(context)` → 노출/활성/비활성 이유 결정 (뷰와 실제 상태 판정은 중복하지 않음). | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:42 | - `_on_info_primary_action()` → 현재 컨텍스트 검사 후 건설·배치 대기·개체 제거 중 하나로 분배. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:43 | - `_build_selected()` → 기존 즉시 건설 가드/소유 갱신 유지. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:44 | - `_begin_new_unit_placement(unit_type_id)` → 05의 `PLACE_NEW` 진입, **아직 개체를 생성하지 않음**. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:45 | - `_cancel_pending_placement()` → 신규 위치 지정 대기만 종료. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:46 | - `_remove_placed_instance(instance_id)` → 준비 단계·개체 존재 검사 후 개별 개체 제거(05의 모델). | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:47 | - `_focus_requirement(building_id)` → 필수 건물을 찾아 현재 트리에서 숨겨져 있으면 `full_tree_view`로 전환하고 해당 노드를 선택·포커스. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:48 | - `_show_related_units(building_id)` → NODES의 `requires`/부모 체인으로 관련 병종을 산출하고 동일 정보창 내 선택 링크 제공. 선택한 병종은 … | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:49 | - `_return_to_tree_context()` → 전장 개체 선택만 해제하고 마지막 트리 노드(HQ 폴백) 정보로 복귀. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:50 | - `_refresh_info_panel()` → 현재 UI 및 버튼 상태를 단일 경로로 갱신. | `game.gd::_resolve_info_context / _get_info_actions / _focus_requirement / _show_related_units` | 함수 경계 구현 일치 |
| 04:52 | **미결정 정책: 선언만 두고 실행 기능은 만들지 않는 경계:** | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:55 | \| `_request_upgrade_purchase(unit_id, upgrade_key)` \| A/B 가격, 영구 소유, 추가 해금 조건, 실제 효과 미승인 \| 구매 버튼 없음; … | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:56 | \| `_request_building_refund(building_id)` \| 교차 선행 시설 환불과 저장 처리 미결정 \| 환불 버튼 없음 \| | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:57 | \| `_request_paid_unit_production(unit_id)` \| 정식 생산 비용/물자 규칙 미승인 \| 현재 무료 시연 배치만 \| | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:58 | \| `_request_range_overlay(instance_id)` \| HP/사거리 숫자·격자 거리 판정/사선 등 미정 \| 사거리 표시 기능 없음, 값은 '미정' \| | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:59 | \| `_request_combat_reposition(instance_id, cell)` \| 전투 도중 유닛 이동 정책 미확정 \| 전투 중 이동 불가 \| | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:61 | - 위 함수는 **입력·결과·검증 경계를 나타내는 미사용 비실행 스텁**만 허용한다. 내부에서 임의 자원을 차감하거나, 배열을 수정하거나, `pass` 후 성공을 반환하면 안 된다. | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:62 | - 권장 스텁 구현은 `false`/실패 결과와 사유(`정책 미정`)를 반환하도록 하고 UI에서 호출하지 않는다. 필요한 최소 함수만 만들고 임의의 범용 이벤트 시스템을 구축하지 않는다. | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:63 | - 정책 승인 전 스텁을 테스트로 성공 처리하지 않는다. '추후 연결'이라는 문구만 내고 실동작하는 버튼도 만들지 않는다. | `game.gd::_request_upgrade_purchase / _request_building_refund / _request_paid_unit_production / _request_range_overlay / _request_combat_reposition` | 미확정 정책 실행 없음 |
| 04:66 | 1. 01/03 기반 정보창 콘텍스트와 버튼 렌더링 정리. | `game.gd::_refresh_info_panel / _return_to_tree_context` | 구현 순서 완료 |
| 04:67 | 2. 기존 건설/해금 안전가드 유지, HQ/기보유 버튼 숨김, 잠금 이유 및 부족 시설 이동 연결. | `game.gd::_refresh_info_panel / _return_to_tree_context` | 구현 순서 완료 |
| 04:68 | 3. 05의 신규 배치 대기/개별 배치 제거 모델 및 행동을 연결. | `game.gd::_refresh_info_panel / _return_to_tree_context` | 구현 순서 완료 |
| 04:69 | 4. 관련 병종 링크/트리 포커스, 중복 입력 가드 및 로그를 연결. | `game.gd::_refresh_info_panel / _return_to_tree_context` | 구현 순서 완료 |
| 04:70 | 5. 미결정 기능은 위 한정 스텁만 추가하되 결제·능력치·전투 AI 로직 구현하지 않음. | `game.gd::_refresh_info_panel / _return_to_tree_context` | 구현 순서 완료 |
| 04:73 | - 8건물×보유/미보유×잠금/해금, 12유닛×잠금/가능/슬롯 가득, 2단계(준비/전투), 전장 개체의 유효/무효 선택을 각각 검사. | `tests::_check_action_matrix / _check_field_placement / _run` | 8건물·12유닛 액션 경로 헤드리스 PASS, 모든 조합 수동 QA는 미검증 |
| 04:74 | - 시연 건설 시 G 불변·즉시 소유·v3/v4 저장 일치, 필수 건물 이동이 보이지 않는 트리에서도 작동, 관련 목록에 무관한 병종이 섞이지 않음. | `tests::_check_action_matrix / _check_field_placement / _run` | 헤드리스 통과; 실제 UI QA 별도 |
| 04:75 | - 배치 대기 클릭만으로 개체 수 증가하지 않음; 셀 선택 후 정확히 1기, 제거 시 선택한 instance_id 1기만 제거. | `tests::_check_action_matrix / _check_field_placement / _run` | 헤드리스 통과; 실제 UI QA 별도 |
| 04:76 | - 스텁 버튼이 실사용 가능한 상태로 노출되지 않음; 미승인 경제/강화/전투 수치가 게임 상태에 영향 없음. | `tests::_check_action_matrix / _check_field_placement / _run` | 헤드리스 통과; 실제 UI QA 별도 |
| 04:77 | - 게임 흐름(대화/일시정지/52주/전투), 전장·정보창 입력 우선, v2/v3 저장 읽기 회귀를 05와 함께 실행. | `tests::_check_action_matrix / _check_field_placement / _run` | 헤드리스 52주/입력/저장 PASS, 실제 ESC·브라우저 QA 미검증 |
| 04:80 | - 건물 구매 가격/환불, 강화 연구 구매, 정식 전투 스탯·AI, 매크로/다중 선택, 새 UI 화면은 이번 구현 범위 아님. | `승인 제외 범위` | 정책 유보 준수 |

### W52_05: W52_05_BATTLEFIELD_PLACEMENT_INTERACTION_IMPLEMENTATION_DESIGN_2026-11-04.md

| 원문 행 | 내용 요지 | 코드·검증 근거 | 판정 |
|---|---|---|---|
| 05:3 | - 문서 상태: **구현 지시용 상세 설계**, 코드 미구현. | `설계 범위 / game.gd::_start_field_interaction / _finish_field_interaction` | 코드 일치 |
| 05:4 | - 코드 기준: main 3a85347295377557a7b2c57d539206c4f1d01518 및 AGENTS.md; 01~04 정보창 설계와 연계. | `설계 범위 / game.gd::_start_field_interaction / _finish_field_interaction` | 코드 일치 |
| 05:5 | - 핵심 조작: **우측 기존 유닛 클릭 = 개체 선택 + 배치 편집 가능한 상태**; **드래그 = 위치 이동**; **고정 정보창의 '배치 취소' = 해당 개체 1기 제거**. 별도의… | `설계 범위 / game.gd::_start_field_interaction / _finish_field_interaction` | 코드 일치 |
| 05:6 | - PC/Web 공통 기능. 전투 중 이동·다중 선택·정식 능력치 수치 도입은 이번 범위가 아니다. | `설계 범위 / game.gd::_start_field_interaction / _finish_field_interaction` | 코드 일치 |
| 05:9 | - 현재 scripts/game.gd의 placements는 유닛 ID만 담는 Array[String]이며 개별 instance_id, 좌표, HP는 없다. _draw_field()는 배… | `game.gd::placements / FIELD_RECT / _grid_size / phase` | 기존 자료 모델 갱신·CI 통과 |
| 05:10 | - _click_ally()는 우측 전장 아군 유닛 클릭을 병종 노드 선택으로 연결하지만, 같은 병종 여러 기를 개별적으로 구분하지 못한다. | `game.gd::placements / FIELD_RECT / _grid_size / phase` | 기존 자료 모델 갱신·CI 통과 |
| 05:11 | - 오른쪽 전장: Rect2(1376,84,544,652), 격자 한 칸 46×46 논리 px. 현재 _grid_size(): W01~13=6×6, W14~26=8×8, W27~39=10… | `game.gd::placements / FIELD_RECT / _grid_size / phase` | 기존 자료 모델 갱신·CI 통과 |
| 05:12 | - 단계: dialogue, prepare, battle, result. 현재 건설/배치는 dialogue/prepare에만 허용되며, 주차 변경 시 배치 초기화·건물 보유 유지. | `game.gd::placements / FIELD_RECT / _grid_size / phase` | 기존 자료 모델 갱신·CI 통과 |
| 05:15 | 두 종류의 개념을 구분한다: '새 병종 배치 위치 지정'은 명시적 PLACE_NEW 상태가 필요하나, **기존 개체를 선택하면 즉시 편집 가능한 상태**이므로 별도 MOVE_MODE 버튼… | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:19 | \| 트리 병종 선택·해금·12칸 미만 \| 정보창 '배치' \| PLACE_NEW 진입, 배치 가능한 아군 빈 칸 안내; **아직 개체 생성하지 않음** \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:20 | \| PLACE_NEW \| 빈 아군 칸 1회 클릭 \| 새 instance_id를 가진 유닛 정확히 1기 생성, 그 개체 선택·정보창 표시, NORMAL 복귀 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:21 | \| PLACE_NEW \| 점유 칸/적군/범위 밖 클릭 \| 생성하지 않고 대기 유지, 불가 원인 안내 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:22 | \| PLACE_NEW \| 정보창 '위치 지정 취소' \| 대기만 종료, 트리 병종 정보로 복귀; 기존 개체 제거 없음 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:23 | \| NORMAL·기존 아군 유닛 \| 8px 미만 움직임으로 클릭 \| 개체 선택 테두리, HP/사거리 정보(실제 데이터만), 트리 병종 강조, 편집 가능 컨텍스트 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:24 | \| NORMAL·기존 아군 유닛 \| 8px 이상 드래그하여 빈 아군 칸에 놓기 \| instance_id 유지, grid_cell만 변경, 그 개체 선택 유지 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:25 | \| NORMAL·기존 아군 유닛 \| 점유/적군/범위 밖에 놓기 \| 원래 셀 유지, 개체 복제·소멸·교환 없음 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:26 | \| NORMAL·선택 개체 \| 정보창 '배치 취소' \| 선택한 개체 1기만 제거, 병종 해금·시설 보유·G 변경 없음 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:27 | \| NORMAL·빈 아군 칸 \| 클릭 \| 전장 개체 선택만 해제, 마지막 트리 노드(HQ 폴백) 정보로 복귀 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:28 | \| battle/result \| 아군 개체 클릭 \| 정보 및 트리 병종 강조만 허용 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:29 | \| battle/result \| 배치·드래그·배치 취소 \| 불가, 개체/위치 불변 \| | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:31 | - 단순 클릭은 이동이 아니다. 드래그를 시작해도 실제 모델의 위치 변경은 유효한 셀에서 포인터를 놓을 때 **한 번만** 일어난다. | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:32 | - PLACE_NEW 중 기존 유닛 클릭은 다른 개체 선택이 아닌 점유 불가 안내. 취소 후 기존 개체 선택 가능. 배치 대기가 중복 시작되어 2기를 생성하지 않도록 한다. | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:33 | - 한 기가 있는 셀로 이동하려고 놓으면 교환하지 않고 이동을 거부한다. | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:34 | - 전투 준비 중에만 새 유닛 배치, 기존 유닛 드래그·제거 가능. dialogue 단계는 기존 코드가 허용하므로 유지(대화 레이어 클릭과 혼선 없이). 전투 중에는 개체를 선택해 정보만… | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:35 | - ESC는 main.gd의 일시정지와 충돌하므로 **명시적 '위치 지정 취소' 버튼**을 필수로 제공한다. ESC를 별도 취소로 매핑하려면 이벤트 우선순위와 기존 ESC 동작 검증 후에… | `game.gd::_get_info_actions / _confirm_pending_at / _finish_field_interaction / _remove_placed_instance` | 코드 일치·CI 통과; 실제 포인터 QA 별도 |
| 05:38 | - 상태 필드 권장: placement_mode = NORMAL 또는 PLACE_NEW, selected_tree_node_id(기본 hq), selected_instance_id(없으면… | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 코드 일치·CI 통과 |
| 05:39 | - 정보창의 활성 컨텍스트: 유효한 selected_instance_id가 있으면 전장 **개체** 정보, 없으면 selected_tree_node_id의 **종류/건물** 정보. 한 번… | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 코드 일치·CI 통과 |
| 05:40 | - 트리 노드 직접 클릭 → 개체 선택 해제, 배치 대기는 취소, 해당 트리 정의 정보 표시. 전장 개체 클릭 → 같은 unit_id의 **트리 노드/부모 경로만 시각 강조**; 이 때문… | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 코드 일치·CI 통과 |
| 05:41 | - 전장 개체 클릭 시 병종 노드가 가시 영역 밖이라면 한 번만 부드럽게 포커스하고, 이미 화면에 읽을 수 있게 보이면 카메라를 옮기지 않는다. 개체를 드래그하는 동안 트리 카메라는 움직… | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 상태/코드 일치, 실제 마우스 포커스·보간 픽셀 QA 미검증 |
| 05:42 | - 선택 이벤트의 상호 재발행(트리 선택 → 전장 선택 → 다시 트리 선택)으로 무한 루프가 생기지 않도록 한다. | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 코드 일치·CI 통과 |
| 05:43 | - 전장 빈 칸 클릭은 개체 선택만 해제하고 마지막 트리 선택을 유지한다. HQ 기본/주차 시작은 02를 따른다. | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 코드 일치·CI 통과 |
| 05:44 | - 정보창의 절대 좌표와 전장 크기는 선택/이동에 의해 바뀌지 않는다(01). | `game.gd::_select_node / _select_field_instance / _active_tree_node_id / _selected_ancestors` | 코드 일치·CI 통과 |
| 05:47 | 최소 실제 구현 자료는 다음과 같이 사용한다. 필드 이름은 기존 코드 충돌을 확인하여 정한다. | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:51 | \| instance_id \| 고유 문자열 \| 여러 소총병도 서로 다른 ID, 이동 후 동일, 저장·복구 후 유지 \| | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:52 | \| unit_id \| NODES에 존재하는 병종 ID \| kind=unit이며 주차·필수 시설 조건을 만족 \| | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:53 | \| grid_cell 또는 col,row \| 격자 정수 좌표 \| 아군 영역 안, 모든 개체 간 셀 중복 0 \| | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:54 | \| hp_current \| **미도입** \| 전투 시스템 수치가 확정된 뒤에만 추가 \| | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:56 | - placements:Array[String]를 최소한 Array[Dictionary]의 {instance_id, unit_id, col, row}로 전환한다. 위치와 ID를 리스트 인… | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:57 | - HP/최대 HP/사거리/공격력 등은 정의된 실제 모델에서 읽는다. 현재 정식 수치가 없으므로 가짜 100HP, 3칸, 무작위 공격력을 넣지 않는다. | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:58 | - 기존 배치 한도 12기를 유지한다. 배치/이동/취소는 건물 보유, 유닛 해금, G에 영향을 주지 않는다. | `game.gd::placements / _instance_index / _instance_at_cell / save_manager.gd::_valid_placements` | 코드 일치·CI 통과 |
| 05:61 | - _grid_size() 및 격자 원점/46px 간격은 **단일 계산 경로**로 사용하여 그리기·클릭·드래그 미리보기·저장 셀 변환이 어긋나지 않게 한다. | `game.gd::_grid_origin / _field_cell / _update_field_drag / _draw_field` | 코드 일치·CI 통과; 실화면 QA 별도 |
| 05:62 | - 스크린 좌표 → 셀 좌표 변환 함수, 아군 유효 셀 함수, 해당 셀 점유 개체 조회 함수를 마련한다. 기존 _click_ally()의 배열 인덱스 기반 판정은 대체한다. | `game.gd::_grid_origin / _field_cell / _update_field_drag / _draw_field` | 코드 일치·CI 통과; 실화면 QA 별도 |
| 05:63 | - 드래그 시작 시 선택 개체 ID/원래 셀/마우스 시작 위치 기록, 움직임 8px 미만은 클릭, 이상만 이동 후보 셀 프리뷰. 손을 놓으면 유효성 재검사 후 위치 1회 확정. | `game.gd::_grid_origin / _field_cell / _update_field_drag / _draw_field` | 코드 일치·CI 통과; 실화면 QA 별도 |
| 05:64 | - 정보창의 버튼·스크롤은 전장 드래그/기술트리 드래그가 시작되지 않게 소비; 필드 입력이 TreeClip으로 전달되지 않음. 대화창과 우측 전장/좌측 기술트리 입력 충돌 방지. | `game.gd::_grid_origin / _field_cell / _update_field_drag / _draw_field` | 헤드리스 입력 핸들러 검사 PASS, 실제 PC/Web 이벤트 QA 미검증 |
| 05:65 | - 적군 유닛을 선택/배치 변경하는 기능은 추가하지 않는다. 기존 타이머 시연 전투를 유지한다. | `game.gd::_grid_origin / _field_cell / _update_field_drag / _draw_field` | 코드 일치·CI 통과; 실화면 QA 별도 |
| 05:68 | - 위치 없는 기존 v3 placements를 사전 개체 포맷으로 조용히 재정의하지 않는다. **SAVE_VERSION=4 증가를 권장**한다. | `save_manager.gd::SAVE_VERSION / _valid_placements / _migrate_legacy_placements` | 저장 스모크 통과 |
| 05:69 | - v4 기존 week,g,phase,dialogue,help,buildings 유지 + placements:Array[Dictionary] 요소 {instance_id:String, u… | `save_manager.gd::SAVE_VERSION / _valid_placements / _migrate_legacy_placements` | 저장 스모크 통과 |
| 05:70 | - v4 로드 검사: 필수 필드 자료형, 고유/비어 있지 않은 ID, 병종 유효성, 현재 주차·건물 조건, 12기 제한, 아군 영역, 격자 범위, 점유 중복 검사. 잘못된 저장은 정책에 … | `save_manager.gd::SAVE_VERSION / _valid_placements / _migrate_legacy_placements` | 저장 스모크 통과 |
| 05:71 | - v2/v3 읽기는 기존 문자열 배열 순서를 **해당 주차의 기존 자동 배치 좌표**로 전환; 유효하지 않은 구 시연 유닛 ID는 기존 원칙대로 제외. v1은 계속 거부. | `save_manager.gd::SAVE_VERSION / _valid_placements / _migrate_legacy_placements` | 저장 스모크 통과 |
| 05:72 | - 새 게임은 개체 0기, 다음 주차 진입은 배치 초기화·건물 유지. 저장 → 이어하기에서 같은 주차 개체 ID와 위치가 재현되어야 한다. battle 저장 상태는 기존처럼 prepare… | `save_manager.gd::SAVE_VERSION / _valid_placements / _migrate_legacy_placements` | 저장 스모크 통과 |
| 05:73 | - 현재 save_manager.gd v3의 _valid_buildings 건물 부모·주차 검증을 후퇴시키지 않는다. | `save_manager.gd::SAVE_VERSION / _valid_placements / _migrate_legacy_placements` | 저장 스모크 통과 |
| 05:76 | 1. 게임 진입 HQ 선택, 트리 소총병 선택 → '배치' 버튼만으로 0기 → 빈 아군 칸 클릭 후 1기 생성/정보창 개체 전환. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:77 | 2. 같은 소총병 2기 다른 위치에 배치 → 각각 개별 클릭하면 서로 다른 instance_id/위치, 트리 노드는 소총병 하나만 강조. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:78 | 3. 기존 소총병 A를 빈 칸 B로 드래그 → A 셀 비고 B에 같은 ID 1기만 존재; 동일 정보창 유지. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:79 | 4. 점유 셀/적군/영역 밖 드롭은 원위치. 8px 이하 움직임은 단순 선택. 배치 도중 다른 곳을 눌러도 중복 생성 금지. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:80 | 5. 정보창 '배치 취소' → 선택한 ID 1기만 제거; 다른 유닛·G·건물 상태 불변. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:81 | 6. 12기 채우면 배치 비활성화, 제13기 차단. 전투/결과 중 선택은 가능하나 이동/취소/배치 차단. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:82 | 7. 트리 선택 ↔ 전장 개체 선택 ↔ 빈 셀 클릭 전환에서 정보창/경로/카메라 동기화, 반복 선택 루프 및 드래그 중 카메라 이동 없음. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:83 | 8. W13→14, W26→27, W39→40 격자 크기 경계에서 좌표 판정 검사. 배치 초기화와 52주 진행, 도움말/대화/ESC/전투 시연 회귀. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:84 | 9. v2/v3 로드→v4 저장→재개, v4 ID/셀 중복·적군 셀·범위 밖·미존재 병종·주차 불만족 거부, v1 계속 거부. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export 통과; 실브라우저 QA 별도 |
| 05:85 | 10. 정보창과 전장의 포인터 입력 분리, TreeClip 20노드/19선, 포커스·패닝 49점 회귀, Godot 헤드리스 씬/웹 Export. 실제 브라우저 QA는 별도로 검증 표시. | `tests::_check_field_placement / _check_action_matrix / _run; Actions 41800013533` | 헤드리스·Web Export PASS, 실제 브라우저 QA 미검증 |
| 05:88 | 1. 참조 분석: scripts/game.gd에서 placements 사용 전체, scripts/save_manager.gd, tests/w52_ui_smoke.gd 및 메뉴 저장 경로 … | `game.gd::배치 데이터·정보창 / save_manager.gd / tests` | 구현·대조 순서 완료 |
| 05:89 | 2. 개체 모델+셀 유효성 검사와 공통 좌표 함수를 추가; 기존 자동 배치를 명시적 클릭 위치 지정으로 전환. | `game.gd::배치 데이터·정보창 / save_manager.gd / tests` | 구현·대조 순서 완료 |
| 05:90 | 3. 클릭 선택/드래그 이동/제거, 전장 선택 테두리/배치 셀 프리뷰 구현. 8px 판정과 입력 우선순위 확인. | `game.gd::배치 데이터·정보창 / save_manager.gd / tests` | 구현·대조 순서 완료 |
| 05:91 | 4. 01~04 고정 정보창·선택 컨텍스트·버튼 연결, 동일 병종의 개별 유닛 정보/경로 강조 통합. | `game.gd::배치 데이터·정보창 / save_manager.gd / tests` | 구현·대조 순서 완료 |
| 05:92 | 5. v4 저장·v2/v3 호환 변환·정적 테스트 도입. 설계 대조·불일치 수정·재검사 루프 반복. | `game.gd::배치 데이터·정보창 / save_manager.gd / tests` | 구현·대조 순서 완료 |
| 05:93 | 6. 기능 브랜치에서 허용된 테스트 → 사용자 요청 시에만 해당 변경을 devel에 반영. main에 자동 머지하지 않는다. | `game.gd::배치 데이터·정보창 / save_manager.gd / tests` | 구현·대조 순서 완료 |
| 05:96 | - 정식 HP/사거리 및 공격 판정의 단위와 규칙, 효과 범위 시각화, 전투 중 직접 이동/이동력·이동 제한, 유닛 간 자리 교환·다중 선택. | `game.gd::_request_upgrade_purchase / _request_combat_reposition` | 미확정 정책 유보 준수 |
| 05:97 | - 유닛 구매 비용/환불/업그레이드 구매 등 미승인 경제 규칙을 이번 UI/배치 구현에 섞지 않는다. | `game.gd::_request_upgrade_purchase / _request_combat_reposition` | 미확정 정책 유보 준수 |

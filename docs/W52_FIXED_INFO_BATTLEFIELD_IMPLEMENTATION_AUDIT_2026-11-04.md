# W52 2026-11-04 구현설계 01~05 코드 대조·검증 기록

- 작업 브랜치: `feature/fixed-node-info-battlefield-implementation-20261104` (GitHub 최신 `main` `3a85347295377557a7b2c57d539206c4f1d01518`에서 분기).
- 기준 설계: 같은 브랜치로 가져온 `docs/W52_01_*` ~ `docs/W52_05_*`의 2026-11-04 설계서 5개.
- 대조 대상: `scripts/game.gd`, `scripts/save_manager.gd`, `tests/w52_ui_smoke.gd`, 기존 `main.gd`·`project.godot`·`scenes/game.tscn` 인터페이스.
- 판정 정의: **일치(정적)** = 코드·자료 계약·이벤트 경로와 테스트 선언을 대조하여 부합함. **미검증** = 실제 Godot 실행/렌더링/포인터 조작/헤드리스·웹 내보내기를 실행해 확인하지 못함. **불일치** = 설계와 소스가 확인 가능하게 다른 경우.
- 주의: 작성된 Godot 스모크 테스트는 **실행하지 않았다**. AGENTS.md의 검사 정책과 현재 도구 제약상 기능 브랜치 전용 Actions 실행이 발생하지 않았으며, 런타임 성공으로 기록하지 않는다.

## 01 고정 정보창

| 요구사항 | 판정 | 실제 코드·씬·입력·검사 근거 |
|---|---|---|
| 단일 고정 패널, 위치/크기 불변 | 일치(정적) | `game.gd::INFO_PANEL_RECT=Rect2(930,170,420,560)`, `_create_controls()`에서 `NodeInfoLayer` 위치/크기 설정, `_info_panel_rect()`; 노드 상대 팝업 계산 제거 |
| 전장/헤더/대화와 패널 비겹침 | 일치(좌표 대조), 미검증(실측) | x=930..1350은 전장 x>=1376 밖, y=170..730은 헤더 0..84/대화 y>=778 밖. 픽셀·폰트 렌더 미검증 |
| 헤더·스크롤 본문·고정 액션 푸터 | 일치(정적), 미검증(실측) | `info_title`, `info_status`, `info_scroll`, `info_reason`, `deploy_button`, `secondary_button`; overflow·스크롤 위치는 실사용 미검증 |
| 트리 정의와 전장 개체가 정보창 하나 공유 | 일치(정적) | `_resolve_info_context()` → `_refresh_info_panel()`; 개별 업그레이드 떠다니는 창 제거 |
| 정보창 클릭/휠/드래그가 트리 패닝을 시작하지 않음 | 일치(정적), 미검증(실제 포인터) | `NodeInfoLayer`·`info_scroll` 마우스 STOP, `_gui_input()`의 `INFO_PANEL_RECT` 가드, `_node_at()` 제외 |
| 112% 선택·8px 임계값·20노드/19선·24강화 유지 | 일치(정적), 미검증(씬 구동) | `NODES` 20, parent 19, `UPGRADES` 12×2, `_node_half_size`/focus 1.12, `DRAG_THRESHOLD=8`; 스모크 테스트 기술트리 계약 |
| 패널 뒤 노드를 가시로 오인하지 않음, 49 pan점과 12프레임 | 일치(정적), 미검증(스모크 실행) | `_readable_tree_area()`의 x<918 및 대화 상단 경계, `_clamp_pan()`; `tests/w52_ui_smoke.gd` 49점·12프레임 테스트 유지 |
| PC/Web 단일 프로젝트 및 Canvas 좌표 | 일치(설정·코드), 미검증(환경) | `project.godot`의 동일 1920×1080 캔버스/1280×720 창/Compatibility, 플랫폼별 별도 씬 없음 |

## 02 첫 HQ 선택과 선택 원점

| 요구사항 | 판정 | 실제 코드·상태·검사 근거 |
|---|---|---|
| 새 게임 처음 HQ 선택 및 HQ 정보 표시 | 일치(정적), 미검증(실제 프레임) | `selected_id="hq"`, `_set_week_intro()`, `_ready()->_refresh_all()`; `_check_integrated_tree()`에서 기본 HQ/제목 확인 |
| v2/v3/신규 v4 이어하기 HQ 선택 | 일치(정적), 미검증(저장 실행) | `restore_state()`의 HQ 초기화, `_refresh_all()` 및 저장 변환 테스트 |
| 다음 주 진입 HQ·카메라 리셋, 기존 시설 유지/배치 초기화 | 일치(정적), 미검증(52주 실행) | `_battle_action() -> _set_week_intro()`; `placements.clear()`, `owned_buildings` 불변 |
| 직접 트리 선택은 HQ 기본값을 덮어쓰고 지속 | 일치(정적) | `_select_node(id,user_input=true)`, `user_selected_context` |
| 전장 개체 선택/빈 아군 셀 클릭 시 컨텍스트 복귀 | 일치(정적) | `_select_field_instance()`, `_return_to_tree_context()`, 마지막 `selected_id` 보존 |
| W01 3번째 튜토리얼에서만 소총병 자동선택, 사용자 선택은 불변 | 일치(정적), 미검증(대화 구동) | `_advance_dialogue()`의 week==1 및 user_selected_context 가드, 새 테스트 |
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
| 필요시설 찾기/관련 병종 보기 실제 노드 포커스 | 일치(정적), 미검증(버튼 사용) | `_focus_requirement()`, 필요 시 `full_tree_view` 전환; `_show_related_units()` + 선택 링크 |
| 배치 버튼은 새 유닛 생성 전 PLACE_NEW 대기 진입 | 일치(정적) | `_on_info_primary_action()` → `_begin_new_unit_placement()` (생성 없음) |
| 대기 취소 vs 개체 1기 배치 취소 분리 | 일치(정적) | `_cancel_pending_placement()` vs `_remove_placed_instance()` |
| 이미 건설, 12칸 초과, 중복 배치 대기 방지 | 일치(정적), 미검증(실제 버튼 반복) | `_build_selected()` 보유 가드; `_begin_new_unit_placement()` 상태/슬롯 가드; 스모크 테스트 추가 |
| 유보 기능 경계만, 버튼 실행 불가 | 일치(정적) | `_request_upgrade_purchase/_request_building_refund/_request_paid_unit_production/_request_range_overlay/_request_combat_reposition`가 false만 반환; 실제 호출 버튼 없음 |
| 정책 미정 가격·환불·전투 이동·강화 적용 미구현 | 일치(정적) | 승인되지 않은 경제/전투 게임 상태 및 저장 항목 추가 없음 |

## 05 우측 전장 및 저장

| 요구사항 | 판정 | 코드·입력·상태·저장·검사 근거 |
|---|---|---|
| PLACE_NEW 빈 아군 셀 클릭 시 1기 생성, 새 ID | 일치(정적), 미검증(포인터 구동) | `_confirm_pending_at()`; `unit_%06d` ID, `placements.append`, 대기 해제 및 개체 선택 |
| PLACE_NEW 점유·적군·범위 밖 실패 시 대기 유지 | 일치(정적), 미검증(포인터 구동) | `_is_ally_cell()`, `_instance_at_cell()`, 실패 로그와 미변경 모델 |
| 기존 개체 클릭 = 개체정보·기술트리 강조(정의정보로 대체 안 됨) | 일치(정적) | `_select_field_instance()`, `_active_tree_node_id()`, `_selected_ancestors()`, `selected_instance_id` |
| 8px 미만 클릭 / 8px 이상 드래그와 1회 드롭 확정 | 일치(정적), 미검증(실제 포인터) | `_update_field_drag()`의 `DRAG_THRESHOLD`, `_finish_field_interaction()`에서만 좌표 갱신 |
| 드래그 목표 점유·적군·범위 밖이면 이동/복제/교환 없음 | 일치(정적), 미검증(실제 포인터) | `_finish_field_interaction()`의 점유 및 아군 범위 가드와 거부 로그 |
| 개별 ID 유지, 배치 취소 시 선택 1기 제거 | 일치(정적) | `_instance_index()` 및 `remove_at(index)`; G·건물 배열 불변 |
| 빈 아군 칸 클릭 마지막 트리 정보로 복귀 | 일치(정적) | `_return_to_tree_context()` |
| 전투/결과 선택은 가능하지만 배치/이동/제거 금지 | 일치(정적) | phase 가드 및 액션 매트릭스, 새 스모크 테스트 |
| 전장 드래그가 트리 카메라를 이동시키지 않음 | 일치(정적), 미검증(실제 포인터) | `_start_field_interaction()` 카메라 타깃 중단, field drag 분리 |
| 격자 46px 및 주차별 6×6/8×8/10×8/10×10 | 일치(정적), 미검증(실제 좌표계) | `grid_size_for_week()`, `_grid_origin()`, `_field_cell()`, `_draw_field()`, 경계 테스트 |
| 12기 제한 및 매주 배치 초기화·시설 보존 | 일치(정적), 미검증(52주 실행) | `_get_info_actions()`, `_begin_new_unit_placement()`, `_confirm_pending_at()`, `_set_week_intro()` |
| 저장 버전 v4, 개체 ID/병종/셀 정수 저장 | 일치(정적), 미검증(실제 파일 왕복) | `SAVE_VERSION=4`, `snapshot()`, `save_game()` |
| v4 ID/종류/선행시설/주차/12기/격자·중복 엄격 거부 | 일치(정적), 미검증(스모크 실행) | `_valid_placements()`, `_valid_buildings()`; 잘못된 로드/저장 fixture |
| v2/v3 순서 유지 자동 배치 좌표 변환, 구 시연 ID 제외, v1 거부 | 일치(정적), 미검증(스모크 실행) | `_migrate_legacy_placements()`, `legacy_cell_for_index()`, `load_game()` 분기; v1/v2/v3 fixture |
| battle 저장 상태는 prepare로 복구 | 일치(정적), 미검증(파일 로드 실행) | 기존 `restore_state()` 처리 및 v3→v4 fixture |
| 20노드·19선·49점 패닝·52주·메뉴 경로·Web Export 회귀 | 일치(테스트 코드/기존 경로), 미검증(실행) | `tests/w52_ui_smoke.gd` 회귀 테스트의 구조 확인; Godot CI/실제 PC·Web은 실행하지 않음 |

## 정적 검사·오류 수정 기록

1. 브랜치의 `scripts/game.gd`, `scripts/save_manager.gd`, `tests/w52_ui_smoke.gd`를 GitHub에서 재조회하고 27개 정적 계약 검사(공백, 들여쓰기, 충돌 마커, 중복 함수명, 노드·강화 수, 고정 패널, HQ, 전장 조작·상태, 저장 v4·마이그레이션, 스모크 테스트 커버리지, 구 팝업 제거)를 수행: **27/27 PASS**.
2. 재검사 전에 테스트의 여러 줄 배열 들여쓰기 불일치를 발견하여 수정. 스모크 테스트 실제 실행 결과가 아니라 정적 소스 검사 결과임.
3. 재검사 전에 v4 개체 사전에 미승인 능력치 등 추가 필드가 저장될 여지를 발견하여 정확히 네 필드만 허용하도록 수정. 보유 건물의 부모·주차 검증을 유지.
4. 건물의 관련 병종 보조 버튼이 건설 전에도 의미 있게 노출되고 부족 시설 찾기를 우선하도록 조정. 정보창의 연결 기술시설 안내 추가. 정적 재검사 완료.
5. 입력과 데이터가 연결된 상태 전이의 코드 경로를 점검했으나 Godot 실행·씬 임포트·실제 폰트/스크롤/포인터·저장 파일 왕복·웹 Export는 **미검증**. 그러므로 설계 내용의 **런타임 PASS를 주장하지 않는다**.

## 잔여 상태와 외부 경계

- 확인 가능한 소스 계약에서 발견되어 미수정으로 남긴 **불일치: 없음**. 실사용 결과는 별도 검증 필요.
- 별도 결정 필요: 정식 HP·최대 HP·사거리(단위/판정 방식)·공격력·공격주기, 비용·환불·강화 구매·효과, 전투 중 재배치 정책. 값/구매 기능은 만들어 넣지 않음.
- 로컬 `C:\GPT-Workspace\w52`의 Git 실행·최신 fetch·작업 트리의 전체 변경 상태를 확인할 수 없어 **로컬 경로는 수정하지 않음**. GitHub의 **독립 원격 기능 브랜치에만** 문서/코드/테스트 반영.
- AGENTS.md의 정책에 따라 로컬 게임 실행 및 브라우저 QA는 하지 않음. 기능 브랜치만 업데이트했으므로 `main/devel` Push에 연동된 기존 Actions 헤드리스·웹 Export·Pages 워크플로 실행이 없으며 빌드 PASS/배포 성공은 미확인.
- `main` 병합, `devel` 반영 및 Pages 게시 없음. 기능 브랜치의 검증 후에도 사용자 명시 승인 없이 해당 단계 진행하지 않음.

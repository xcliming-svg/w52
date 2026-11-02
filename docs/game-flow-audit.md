# W52 게임 실행 흐름 — 구현설계 교차검증 기록

- 기준일: 2026-11-02
- 기준 설계: `docs/game-flow-design.md` 및 세부 `docs/UI_LAYOUT_DESIGN.md`
- 대상 기능 브랜치: `feature/w52-build-first-ui`
- 검증 범위: 실제 스크립트/씬/Theme/상태 전이/저장 API 정적 대조 + Godot CI 자동 스모크/빌드 검증
- 미검증 범위: 브라우저의 실제 조작·저장소 지속성·음향·화면 픽셀·전체화면 브라우저 정책

## 1. 활성 설계와 소스 대조

| 설계 계약 | 근거 소스 | 대조 결과 |
|---|---|---|
| 시작 1.5초 후 TITLE→MAIN_MENU | `scripts/title.gd::_on_timer_timeout`, `main.gd::_show_title` | 정적 일치 |
| 메뉴의 4개 버튼 및 저장 미존재 시 이어하기 비활성 | `main_menu.gd::set_continue_available`, `main.gd::_show_main_menu` | 정적 일치 |
| W52 Control 게임 시작·새 게임 데이터 초기화 | `scenes/game.tscn`, `main.gd::_start_game`, `game.gd::restore_state` | 정적 일치 |
| ESC 일시정지·재개·설정 이전 화면 복귀 | `main.gd::_input/_pause_game/_resume_game/_close_settings`, pause/settings 메뉴 | 정적 일치 |
| 게임 → 메인 복귀 시 W52 주차/자원/대화/배치 저장 | `main.gd::_leave_game_to_menu`, `game.gd::snapshot`, `save_manager.gd` | 정적 일치, 웹 지속성 미확인 |
| 저장 버전2만 승인 및 버전1 거부 | `save_manager.gd::load_game`의 버전 검사, `tests/w52_ui_smoke.gd` | 정적 일치, CI 테스트 대상 |
| 52주 진행·스킬트리 가시성·팝업·배속 UI | `game.gd`, `tests/w52_ui_smoke.gd`, `UI_LAYOUT_DESIGN.md` | 정적 일치, CI 테스트 대상 |
| 패배 신호 계약 보존, 실제 패배 판정 미구현 | `main.gd::_on_defeated`, `game.gd`의 신호 | 정적 일치, 런타임 판정 비범위 |
| PC/Web 같은 종료·전체화면·오디오 설정 | `main.gd::_quit_game`, `settings_menu.gd`, `settings_manager.gd` | 정적 일치, 브라우저 QA 미실시 |
| 한국어 폰트·향후 에셋 연결점 및 메뉴 Theme | `main.gd`의 폰트 fallback, title/main 씬, `ui_style.gd` | 정적 일치, Web Export 대상 |

## 2. 레거시 차이 조치 및 재대조

1. 기존 문서에 남아 있던 원형 플레이어 WASD 이동·`Node2D/Sprite2D` 게임·게임 좌표 저장 안내를 삭제하고 현재 `Control` W52 씬·상태 저장 규격으로 갱신.
2. `README.md`의 진입 방법·기능 설명과 UI 상세 설계 문서 참조를 현재 코드 기준으로 수정.
3. 이전 이동 데모의 버전1 저장 변환 분기와 사용되지 않는 `PLAYER_FILL`/`PLAYER_OUTLINE`/`custom_font`를 제거. 기존 화면 호출자는 해당 속성을 사용하지 않음을 확인.
4. 변경 후 `scripts/save_manager.gd`, `main.gd`, `scripts/game.gd`, 주요 메뉴 씬/스크립트 간 API와 데이터 계약을 다시 대조.
5. GitHub Actions에서 **stable과 devel 각각** Godot 씬 스모크·Web Export를 실행하고, 결과물 검사 및 Pages 게시 성공을 별도 확인.

## 3. 미검증 사항

- 오디오 리소스가 연결되지 않은 상태에서 음량 슬라이더의 체감 효과
- 실제 브라우저 전체화면, 입력 포커스, 로컬 저장소 영속성 및 웹 종료
- 실제 전투 승패·AI·전투 밸런스·서사
- 픽셀 기반 스킬트리·폰트 및 팝업의 브라우저 시각 검수

자동 테스트의 통과는 위 미검증 항목의 성공을 의미하지 않는다.

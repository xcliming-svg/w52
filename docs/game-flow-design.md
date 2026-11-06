# W52 게임 실행 흐름 및 기본 UI 설계 — 2026-11-02 최종본

- 대상: Godot 4.7.2, PC/Web 동일 게임 씬·GDScript·UI.
- UI 상세 배치·트리 드래그·대화·전장·폰트는 [UI_LAYOUT_DESIGN.md](UI_LAYOUT_DESIGN.md)를 단일 기준으로 삼는다.
- 상위 흐름은 타이틀 → 메인 메뉴 → W52 게임(주차/전투) → 일시정지·설정/메인 메뉴 복귀를 관리한다.
- 실제 전투 AI·패배 판정은 아직 구현되지 않았다.

## 1. 화면 상태와 진입

| 상태 | 진입·전이 | 구현 |
|---|---|---|
| TITLE | 시작 후 약 1.5초에 자동으로 MAIN_MENU | `scripts/title.gd`의 타이머 및 `main.gd`의 `finished` 연결 |
| MAIN_MENU | 새 게임·이어하기·설정·종료 표시 | `scripts/main_menu.gd`; 유효한 저장이 없으면 이어하기 비활성 |
| PLAYING | W52 `Control` 게임을 생성하고 1~52주 대화·배치·전투 시연 진행 | `scenes/game.tscn`, `scripts/game.gd` |
| PAUSED | PLAYING 중 ESC → 시뮬레이션 일시정지; 계속하기·재시작·설정·메인 메뉴 | `main.gd` / `scripts/pause_menu.gd` |
| DEFEAT | 향후 게임 측 `defeated` 신호를 받았을 때만 진입; 저장 삭제 후 재시작·메인 메뉴 | 현재 게임은 실제 패배 신호를 발생시키지 않으므로 일반 플레이에서는 도달하지 않음 |

메인 메뉴와 PAUSED 중 설정 창을 열 수 있다. 설정은 별도 화면 상태가 아닌 오버레이이며, ESC 또는 뒤로 가기로 기존 화면에 복귀한다. `main.gd`가 상태와 화면 소유권을 관리하고 PAUSED/설정 중의 게임 동작을 정지한다.

## 2. 새 게임·저장·이어하기

- **새 게임**: 유효한 메뉴/일시정지/패배 상태에서 기존 진행 저장을 삭제하고 W52 1주차·160G·대화 인덱스 0부터 생성한다.
- **저장 시점**: 게임 중 ESC → 일시정지 → 메인 메뉴로 돌아갈 때 `game.snapshot()`으로 저장한다. 단순 게임 진입만으로 저장하지 않는다.
- **현재 저장 버전 5**: `user://game_save.cfg`의 `session`에는 `version=5`, `week`, `g`, `phase`, `dialogue`, `help`, `placements`, `buildings`, `story`를 사용한다. `story`에는 연속 확인된 단서·카드 인덱스·처리된 전투 ID·엔딩 플래그를 저장하며 검증에 실패하면 복구하지 않는다. 상세 계약은 `W52_V9_STORY_PREIMPLEMENTATION_DESIGN_2026-11-06.md`를 따른다.
- **이어하기**: 유효한 v2·v3·v4·v5 저장을 지원한다. 구 버전은 건물·배치 정보를 기존 규칙대로 변환하지만 실제 승리·단서를 추정하지 않는다. `restore_state()`는 주차·G·대화·배치·서사를 복구하며 전투 중 저장은 준비 단계에서 재개한다.
- **레거시 지원 없음**: 이전 이동 데모의 저장 버전 1(좌표 x/y)은 호환·변환하지 않는다. 이런 저장만 있으면 이어하기가 비활성화되며 새 게임으로 시작한다.
- **재시작**: 이전 저장을 삭제하고 1주차에서 다시 시작한다. **패배** 진입 시에도 해당 진행 저장을 삭제한다.
- **실패 시 동작**: 유효하지 않은 저장은 이어하기에서 제외하고, 저장/삭제 실패는 경고한다. 파일 시스템 실패를 성공으로 표시하지 않는다.

## 3. 공통 입력 및 플랫폼

- 게임 도중 ESC는 PAUSED, PAUSED에서는 재개, 설정 오버레이가 열려 있으면 먼저 설정을 닫는다. `Main`은 항상 입력 처리, 게임 씬은 일시정지 가능한 처리 모드로 동작한다.
- PC/Web은 동일한 `main.tscn`, `scenes/game.tscn`, 메뉴·설정 씬과 코드를 사용한다. 웹을 위해 게임플레이 또는 종료 버튼을 별도 제거하지 않는다.
- **게임 종료**: 공통 버튼은 `SceneTree.quit()`를 호출한다. 웹에서 게임 프로세스 종료 요청이 브라우저 탭 자체를 닫는 것은 아니다.
- **전체화면**: PC/Web 모두 설정의 동일한 토글·DisplayServer 경로를 사용한다. 웹 전체화면은 브라우저 정책상 사용자 제스처에서만 요청하며 플랫폼별 동작 검증은 별도다.
- **음량**: 마스터·음악·효과 음량을 0~100%로 설정하고 `user://settings.cfg`에 보관한다. 오디오 스트림은 아직 연결되지 않았다.

## 4. 구성요소와 연결점

| 파일/씬 | 책임 |
|---|---|
| `main.tscn`, `main.gd` | 상위 화면 상태·게임 세션·일시정지·설정·저장 호출 및 한글 기본 Theme |
| `scenes/title.tscn`, `scripts/title.gd` | 타이틀 자동 전환과 `LogoArt` 선택 삽입 슬롯 |
| `scenes/main_menu.tscn`, `scripts/main_menu.gd` | 새 게임·이어하기·설정·종료 |
| `scenes/game.tscn`, `scripts/game.gd` | 1920×1080 W52 전략 UI, 트리 노드·대화·전투 시연·저장 스냅샷·`defeated` 신호 |
| `scenes/pause_menu.tscn`, `scripts/pause_menu.gd` | 재개·다시 시작·설정·메인 메뉴 |
| `scenes/settings_menu.tscn`, `scripts/settings_menu.gd` | 음량·전체화면 및 설정 복귀 |
| `scenes/defeat_screen.tscn`, `scripts/defeat_screen.gd` | 향후 패배 판정에 연결할 패배 화면 |
| `scripts/save_manager.gd`, `scripts/settings_manager.gd` | v5 진행 저장(v2·v3·v4 읽기 호환)과 별도 환경설정 저장 |
| `scripts/ui_style.gd`, `assets/fonts/` | 공통 팔레트/버튼/패널 규격 및 Nanum Gothic OFL 글꼴 fallback |

타이틀/메인 메뉴의 `BackgroundArt`는 향후 텍스처 연결 슬롯이다. `main.tscn`의 `MenuMusic`·`GameMusic`·`UISound`는 비어 있는 AudioStreamPlayer로 정식 오디오를 포함하지 않는다. 게임 배경 및 노드는 현재 `Control` 캔버스에서 그린다.

## 5. 검증·승격 계약

- `docs/UI_LAYOUT_DESIGN.md`와 본 문서가 코드·씬·저장 포맷과 일치하는지 교차검증하고 불일치는 코드/문서 수정 후 재검증한다.
- Godot 헤드리스 임포트·게임 시나리오 52주·드래그/포커스/가시성·v2·v3·v4→v5 저장 변환/손상 차단·Web Export를 검사한다.
- 메인 승격은 사용자 승인 후 **기능 브랜치의 검증된 변경만** 반영한다. `devel` 전체를 `main`에 병합하지 않는다.
- 실제 브라우저/PC 플레이, 픽셀 기반 UI·폰트 렌더링, 웹 저장 지속성·전체화면은 별도의 수동 검수 항목이다.

# w52

Godot 4.7.2 / GDScript / GL Compatibility 기반 게임 기본 실행 구조.

## 현재 지원하는 화면과 입력

- 실행: 타이틀 표시 후 1.5초에 메인 메뉴 자동 진입 (키 입력 불필요)
- 메인 메뉴: **새 게임 / 이어하기 / 설정 / 게임 종료**
- 새 게임: 현재 임시 게임 화면에서 WASD 또는 방향키로 원형 오브젝트 이동
- 게임 중 **ESC**: 일시정지 메뉴 (계속하기, 다시 시작, 설정, 메인 메뉴)
- **이어하기**: 첫 실행부터 버튼은 표시되지만 저장이 없으면 비활성화. 게임 중 ESC → 메인 메뉴로 돌아가 저장되면 활성화되며, 다시 실행했을 때도 저장이 유효하면 복구 가능
- 설정: 전체/음악/효과음 음량, PC·웹 공통 전체화면 토글 (웹에서는 사용자의 직접 버튼 입력이 필요하며 브라우저별 결과는 플레이 검증 필요)
- 게임 종료: PC와 Web에 동일한 버튼. Web에서는 브라우저 탭이 아닌 게임 실행을 종료
- 패배 화면: 향후 게임 로직이 `defeated` 신호를 낼 때 연결되며 현재는 패배 판정이 없음

게임 규칙(전투, 유닛, 라운드, AI)은 아직 구현하지 않았습니다.

## 로컬 실행

1. Godot 4.7.2에서 `project.godot` 열기
2. F5 실행
3. 타이틀 자동 전환 후 메인 메뉴에서 새 게임 선택

## 웹 내보내기

PC/Web은 동일한 씬 및 UI 코드를 사용합니다. 단일 스레드 Web 프리셋은 `export_presets.cfg`에 있습니다.

```powershell
godot --headless --path . --import
New-Item -ItemType Directory -Force build | Out-Null
godot --headless --path . --export-release "Web" build/index.html
```

## 설계 및 운영 규칙

- 게임 실행 구조: `docs/game-flow-design.md`
- 구현과 설계 대조 기록: `docs/game-flow-audit.md`
- 변경·검증·브랜치 규칙: `AGENTS.md`
- 개발판 확인: https://xcliming-svg.github.io/w52/devel/

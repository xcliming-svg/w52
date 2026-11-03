# W52

Godot 4.7.2 / GDScript / Compatibility 렌더러 기반의 PC·Web 공용 전략 게임 UI 시연판입니다.

## 현재 구현된 화면과 입력

- 실행: 타이틀 약 1.5초 표시 후 메인 메뉴 자동 진입.
- 메뉴: 새 게임 / 이어하기 / 설정 / 게임 종료. 유효한 W52 저장이 없으면 이어하기는 비활성화.
- 새 게임: **1920×1080 W52 전략 UI**, 왼쪽 스킬트리·오른쪽 전장/로그. 1주차부터 52주차까지 대화·노드 선택/유닛 배치·전투 진행·결과 전환을 시연.
- 스킬트리: 배경이나 노드에서 왼쪽 마우스로 드래그. **어느 위치에서도 최소 한 개 노드 아이콘과 이름 라벨이 완전히 보이도록** 화면을 제한. 노드 클릭 시 중앙 포커스·정보창. 실제 AI/밸런스/각 주 고유 서사는 아직 시연값.
- 대화: Space 또는 대화창 클릭으로 다음 대사.
- 도움말: 현재 주차 이하만 열람.
- 전투: 1×/2× 속도 선택, 준비→교전→결과→다음 주.
- 일시정지: 플레이 중 ESC → 계속하기 / 다시 시작 / 설정 / 메인 메뉴.
- 저장: ESC → 일시정지 → 메인 메뉴로 이동하면 W52 **버전2 저장**(주차/G/대화/도움말/배치). 옛 이동 데모의 좌표 저장 형식 1은 지원하지 않으며 이어하기에서 거부.
- 설정: 마스터/음악/효과음, PC·웹 공용 전체화면. 웹에서 전체화면/종료 동작은 브라우저 정책을 따름.
- 패배 화면: 실제 전투 패배 판정은 미구현, 향후 `defeated` 신호로 연결.

**안정판:** https://xcliming-svg.github.io/w52/

**개발판:** https://xcliming-svg.github.io/w52/devel/

## 로컬 실행 및 웹 내보내기

1. Godot 4.7.2에서 `project.godot`을 열고 F5로 실행.
2. 동일 프로젝트의 Web Export 프리셋을 사용해 PC·Web에 같은 씬과 UI를 제공.

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/w52_ui_smoke.gd
New-Item -ItemType Directory -Force build | Out-Null
godot --headless --path . --export-release "Web" build/index.html
```

## 설계 및 검증 문서

- [W52 UI 최종 구현 설계](docs/UI_LAYOUT_DESIGN.md)
- [W52 UI 최종 설계·구현 검증](docs/UI_IMPLEMENTATION_AUDIT.md)
- [상위 게임 실행·저장 흐름 설계](docs/game-flow-design.md)
- [상위 실행 흐름 교차검증](docs/game-flow-audit.md)
- [브랜치·빌드·배포 운영 규칙](AGENTS.md)

Godot CI의 씬 테스트와 Web Export 성공은 실제 브라우저의 픽셀·포인터 입력 QA나 정식 전투 정상동작을 보장하지 않습니다.

# src — 소스 영역

현재 소스는 **기획 검증 데이터와 밸런스 모형**입니다. 실제 Godot 씬 코드를 작성할 때도 이 디렉터리 아래에 둡니다. 기존 w52/main.gd·w52/scenes 등을 임의로 수정하지 않습니다.

| 파일 | 역할 | 상태 |
|---|---|---|
| tree_nodes.json | 121노드, ID/전제관계/좌표/TP·XP 가격·효과 | 데이터 작성 및 참조 무결성 확인 |
| wagons.json | 36객차, 등급·색·기본 DPS·탄종·방어 | 데이터 작성, 게임 밸런스 실측 전 |
| enemies.json | 14적, 형태·색·행동 태그 | 데이터 작성, AI 구현 전 |
| simulate_balance.mjs | 수리 모델 14회 × 5전략 × 32시드 | 함수 직접 실행 및 출력 비교 확인 |
| validate_data.mjs | ID/선행/가격/색상/범위 검사 | 동일 함수 직접 실행 PASS |

실행 (Node.js 필요):

    node tree/src/simulate_balance.mjs
    node tree/src/validate_data.mjs

모형은 고정 시드 기반으로 동일 집계 결과를 출력합니다. 열차/개별 적의 실제 좌표, 레일 접촉, 발사체 개별 궤적, 파편 물리, 기관차 체력, 보스 AI, 충돌 이벤트, 실제 렌더링 부하를 **모델링하지 않습니다**. 이 통계 결과를 게임 성능·실제 재미의 근거로 사용하면 안 됩니다.

향후 권장 씬 분할: game_main.tscn / game_main.gd, battlefield.tscn / battlefield.gd, skill_tree.tscn / skill_tree.gd, train_controller.gd, enemies.gd, combat.gd, debris_vfx.gd, hud.gd, save_store.gd. 요구 확정 전에는 위 게임 파일을 구현 완료로 표시하지 않습니다.

## 다음 AI 구현 인계

- tree/AGENTS.md와 tree/docs/CONTRACT.md가 최신 단일 구현 지침입니다.
- tree/docs/IMPLEMENTATION_MANIFEST.json에 **179개 필수 구현 항목**이 모두 TODO로 남아 있습니다.
- audit_balance_v2.mjs, run_logic_balance_audit.mjs은 설계 후보의 제한된 통계모델이며 Godot 실제 전투가 아닙니다.
- static_handoff_audit.mjs는 문서 20개 AI 결정을 정적으로 교차 확인하기 위한 소스 파일이며 게임 실행 테스트가 아닙니다.
- 실제 씬과 엔트리 project.godot는 새 구현 단계에서 tree/src/ 하위에 작성합니다. 지금은 존재하지 않습니다.

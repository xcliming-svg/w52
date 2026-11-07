class_name RRecoveryUi
extends RefCounted

static func recovery_message() -> String:
	return "저장 데이터와 백업 2개가 모두 유효하지 않습니다. 중단된 게임은 재개하지 않고 새 게임을 시작할 수 있습니다."

static func recovery_options() -> Array[String]:
	return ["백업 복구 재시도","새 게임","메뉴"]

static func fallback_or_empty() -> Dictionary:
	return RSaveStore.load_run()

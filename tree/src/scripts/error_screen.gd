class_name RErrorScreen
extends RefCounted

static func with_recovery(details: String) -> String:
	var result: String=details.strip_edges()
	if result.is_empty():
		result="알 수 없는 오류입니다."
	return result+"\n"+RRecoveryUi.recovery_message()

static func heading() -> String:
	return "데이터 또는 저장 오류"

class_name RBrowserStorage
extends RefCounted

static func explanation() -> String:
	return "웹은 브라우저의 IndexedDB(user://)를 사용합니다. 시크릿 모드, 저장소 차단, 데이터 삭제 시 저장이 지속되지 않을 수 있습니다."

static func is_persistent_guaranteed() -> bool:
	return false

static func offer_export() -> String:
	return "중요한 기록을 보관할 경우 브라우저 저장 영역을 삭제하지 마십시오. 영구 보존은 보장되지 않습니다."

class_name RSaveMigration
extends RefCounted

static func compatible(container: Dictionary) -> bool:
	return int(container.get("schema_version",-1))==RSaveSchema.SCHEMA_VERSION

static func migrate(container: Dictionary) -> Dictionary:
	# Unsupported old save versions fail closed: no guessed currency/kill duplication.
	if not compatible(container):
		return {}
	return container if RSaveSchema.valid(container) else {}

static func explanation(container: Dictionary) -> String:
	return "지원되지 않는 버전은 자동 변환하지 않습니다. 백업 저장을 확인하십시오." if not compatible(container) else "저장 데이터 검증 실패. 백업 또는 새 게임을 이용하십시오."

class_name RPlatformService
extends RefCounted

static func is_web() -> bool:
	return OS.has_feature("web")

static func is_windows() -> bool:
	return OS.has_feature("windows")

static func game_executable_name() -> String:
	return "RailSurvivor.exe" if is_windows() else "index.html"

static func save_warning() -> String:
	return RBrowserStorage.explanation() if is_web() else "중단 저장은 사용자의 로컬 저장 영역에 보관됩니다."

static func allow_native_quit() -> bool:
	return not is_web()

class_name RPlatformOptionGuard
extends RefCounted

static func common_settings() -> Array[String]:
	return ["master","music","sfx","vfx","low_flash","shake","color_mode","high_contrast","number_scale","ui_scale","default_speed"]

static func platform_note() -> String:
	return RBrowserStorage.explanation() if RPlatformService.is_web() else "Windows와 웹은 동일한 설정/게임 규칙을 사용합니다."

static func feature_visible(setting: String) -> bool:
	# No concealed gameplay capability across Steam and Web.
	return setting in common_settings()

class_name RFontRegistry
extends RefCounted

# Korean font must be bundled before Web release. File absence is reported,
# never treated as successful packaging.
const REQUIRED_FONT_PATH: String="res://assets/NotoSansKR-Regular.ttf"
const LICENSE_PATH: String="res://assets/NotoSansKR-LICENSE.txt"

static func bundled_font() -> Font:
	if ResourceLoader.exists(REQUIRED_FONT_PATH):
		return load(REQUIRED_FONT_PATH) as Font
	return ThemeDB.fallback_font

static func web_release_ready() -> bool:
	return ResourceLoader.exists(REQUIRED_FONT_PATH) and FileAccess.file_exists(LICENSE_PATH)

static func missing_reason() -> String:
	return "" if web_release_ready() else "한글 웹 폰트 및 라이선스 미포함: 배포 전 확인 필요"

class_name RBrowserQuit
extends RefCounted

static func explanation() -> String:
	return "브라우저 탭은 게임에서 자동으로 닫을 수 없습니다. 메인 메뉴로 돌아간 뒤 탭을 직접 닫으십시오."

static func close_tab_supported() -> bool:
	return false

class_name RHiddenWebPause
extends RefCounted

static func should_suspend(notification: int) -> bool:
	if not OS.has_feature("web"):
		return false
	return notification==Node.NOTIFICATION_APPLICATION_FOCUS_OUT

static func warning() -> String:
	return RBalance.WEB_WARNING+" 백그라운드 전환 시 게임이 일시정지됩니다."

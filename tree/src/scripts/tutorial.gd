class_name RTutorial
extends RefCounted

static func visible_at(tick: int, settings: Dictionary) -> bool:
	return tick<=45*RBalance.TICK_RATE and not bool(settings.get("tutorial_shown",false))

static func instruction(tick: int) -> String:
	var seconds: float=float(tick)/float(RBalance.TICK_RATE)
	if seconds<10.0:
		return "기관차가 사각 레일을 따라 달립니다. 적은 네 모서리를 목표로 이동합니다."
	if seconds<20.0:
		return "처치로 XP와 고철 획득, 생존 시간으로 TP 획득."
	if seconds<30.0:
		return "좌측 트리에서 구매 가능한 노드를 선택하십시오."
	if seconds<45.0:
		return "W 계열로 편성 슬롯 확장, 고철로 객차를 구매하십시오."
	return ""

static func dismiss(settings: Dictionary) -> void:
	settings.tutorial_shown=true

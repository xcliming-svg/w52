class_name RKeyBindings
extends RefCounted

static func action_for(event: InputEvent) -> String:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return ""
	match event.keycode:
		KEY_ESCAPE,KEY_SPACE:return "pause"
		KEY_TAB:return "tree_focus"
		KEY_F:return "research"
		KEY_PLUS,KEY_EQUAL,KEY_KP_ADD:return "speed_up"
		KEY_MINUS,KEY_KP_SUBTRACT:return "speed_down"
		_:return ""

static func controls_text() -> String:
	return "ESC/Space 일시정지 · Tab 트리 초점 · F 연구 · +/- 배속 · 드래그/휠 트리"

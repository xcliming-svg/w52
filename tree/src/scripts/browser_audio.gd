class_name RBrowserAudio
extends RefCounted

var user_interacted: bool=false

func on_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		user_interacted=true
	if event is InputEventKey and event.pressed:
		user_interacted=true
	return user_interacted

func may_play() -> bool:
	return user_interacted or not OS.has_feature("web")

static func guidance() -> String:
	return "브라우저 오디오는 클릭/키보드 입력 이후에 시작합니다."

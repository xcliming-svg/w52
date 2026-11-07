class_name RUiScaling
extends RefCounted

static func preset(value: float) -> float:
	var steps: Array[float]=[0.8,1.0,1.25,1.5]
	var chosen: float=1.0
	var nearest: float=INF
	for step in steps:
		var diff: float=absf(step-value)
		if diff<nearest:
			nearest=diff
			chosen=step
	return chosen

static func apply(control: Control, value: float) -> void:
	if control==null:
		return
	var scale: float=preset(value)
	var theme:=Theme.new()
	theme.default_font_size=int(19.0*scale)
	theme.default_font=RFontRegistry.bundled_font()
	control.theme=theme

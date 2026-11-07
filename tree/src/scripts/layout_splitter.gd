class_name RLayoutSplitter
extends ColorRect

signal ratio_changed(ratio: float)
var dragging: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	color = Color("#344967")
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = bool(event.pressed)
		accept_event()
	elif dragging and event is InputEventMouseMotion:
		var root: Control = get_parent() as Control
		if root != null and root.size.x > 0.0:
			var ratio := 0.50
			ratio_changed.emit(ratio)
		accept_event()

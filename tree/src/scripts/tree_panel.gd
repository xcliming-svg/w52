class_name RTreePanel
extends Control

signal node_selected(node_id: String)
signal buy_requested(node_id: String)

var session
var selected_id: String = "C000"
var zoom: float = 0.65
var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var last_mouse: Vector2 = Vector2.ZERO
var drag_distance: float = 0.0
var search_filter: String = ""
var font: Font
var info_dialog: ConfirmationDialog

func _ready() -> void:
	font = RFontRegistry.bundled_font()
	mouse_filter = Control.MOUSE_FILTER_STOP
	info_dialog = ConfirmationDialog.new()
	info_dialog.title = "기술 가지 정보"
	info_dialog.ok_button_text = "활성화"
	info_dialog.cancel_button_text = "닫기"
	info_dialog.confirmed.connect(func() -> void: buy_requested.emit(selected_id))
	add_child(info_dialog)
	_fit_zoom()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_fit_zoom()

func _fit_zoom() -> void:
	zoom = minf(0.65, maxf(0.20, minf(size.x,size.y) * 0.46 / 660.0))
	queue_redraw()

func set_session(value) -> void:
	session = value
	queue_redraw()

func set_search(value: String) -> void:
	search_filter = value
	if session == null:
		return
	var hits: Array[String] = RTreeSearch.find(session.registry,value)
	for id in hits:
		if session.tree.is_visible(id):
			focus_on(id)
			break
	queue_redraw()

func focus_on(node_id: String) -> void:
	if session == null or not session.tree.is_visible(node_id):
		return
	pan = RTreeCamera.focus(session.registry.nodes[node_id])
	selected_id = node_id
	node_selected.emit(node_id)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			zoom = RTreeInteraction.zoom_wheel(zoom,event.button_index == MOUSE_BUTTON_WHEEL_UP)
			queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse = event.position
				drag_distance = 0.0
			else:
				dragging = false
				if drag_distance < 6.0:
					_select_at(event.position)
			accept_event()
	elif dragging and event is InputEventMouseMotion:
		pan = RTreeInteraction.pan_delta(last_mouse,event.position,zoom,pan)
		last_mouse = event.position
		drag_distance += event.relative.length()
		queue_redraw()
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_show_node_detail()
		accept_event()

func _select_at(point: Vector2) -> void:
	if session == null:
		return
	var id: String = RTreeInteraction.hovered_node(session.registry,point,size,pan,zoom,22.0,session.tree.purchased)
	if id.is_empty():
		return
	selected_id = id
	node_selected.emit(id)
	queue_redraw()
	_show_node_detail()

func _show_node_detail() -> void:
	if session == null or not session.tree.is_visible(selected_id):
		return
	info_dialog.dialog_text = RTreeTooltip.text_for(session.registry,session.tree,session.economy,selected_id)
	info_dialog.get_ok_button().disabled = not session.tree.may_buy(selected_id) or session.paused
	info_dialog.popup_centered(Vector2i(600,310))

func _draw() -> void:
	RTreeRenderer.render(self,session,size,pan,zoom,selected_id,search_filter,font)

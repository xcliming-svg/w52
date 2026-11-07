class_name RTreePanel
extends Control

signal node_selected(node_id: String)
signal buy_requested(node_id: String)

var session
var selected_id: String = "C000"
var zoom: float = 0.39
var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var last_mouse: Vector2 = Vector2.ZERO
var drag_distance: float = 0.0
var search_filter: String = ""
var font: Font

func _ready() -> void:
	font=ThemeDB.fallback_font
	mouse_filter=Control.MOUSE_FILTER_STOP

func set_session(value) -> void:
	session=value
	queue_redraw()

func set_search(value: String) -> void:
	search_filter=value
	var hits: Array[String]=RTreeSearch.find(session.registry,value) if session!=null else []
	if not hits.is_empty():
		focus_on(hits[0])
	queue_redraw()

func focus_on(node_id: String) -> void:
	if session==null or not session.registry.nodes.has(node_id):
		return
	pan=RTreeCamera.focus(session.registry.nodes[node_id])
	selected_id=node_id
	node_selected.emit(node_id)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			zoom=RTreeInteraction.zoom_wheel(zoom,event.button_index==MOUSE_BUTTON_WHEEL_UP)
			queue_redraw()
			accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging=true
				last_mouse=event.position
				drag_distance=0.0
			else:
				dragging=false
				if drag_distance<6.0:
					_select_at(event.position)
			accept_event()
	elif dragging and event is InputEventMouseMotion:
		pan=RTreeInteraction.pan_delta(last_mouse,event.position,zoom,pan)
		last_mouse=event.position
		drag_distance+=event.relative.length()
		queue_redraw()
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode==KEY_ENTER:
		buy_requested.emit(selected_id)
		accept_event()

func _select_at(point: Vector2) -> void:
	if session==null:
		return
	var id: String=RTreeInteraction.hovered_node(session.registry,point,size,pan,zoom)
	if id.is_empty():
		return
	if id==selected_id:
		buy_requested.emit(id)
	selected_id=id
	node_selected.emit(id)
	queue_redraw()

func _draw() -> void:
	RTreeRenderer.render(self,session,size,pan,zoom,selected_id,search_filter,font)

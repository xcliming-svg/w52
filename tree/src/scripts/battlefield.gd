class_name RBattlefield
extends Control

var session
var world_scale: float = 1.0
var offset_world: Vector2 = Vector2.ZERO
var default_font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	default_font = ThemeDB.fallback_font

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_session(value) -> void:
	session = value
	queue_redraw()

func to_world(p: Vector2) -> Vector2:
	return RWorldCoordinates.screen_to_world(p,world_scale,offset_world)

func _draw() -> void:
	var fit: Dictionary=RViewportAdapter.fit_world(size)
	world_scale=float(fit.scale)
	offset_world=Vector2(fit.offset)
	draw_rect(Rect2(Vector2.ZERO,size),Color("#060c17"))
	var camera_shift: Vector2=Vector2.ZERO
	if session != null:
		camera_shift=RGameCamera.visual_offset(session.visuals,session.options)
	draw_set_transform(offset_world+camera_shift,0.0,Vector2.ONE*world_scale)
	draw_rect(Rect2(Vector2.ZERO,RBalance.WORLD_SIZE),Color("#0a1326"))
	# Track and center portal are rendered independently of collision rules.
	RRailRenderer.paint(self)
	RPortalRenderer.paint(self,session.visuals.time if session!=null else 0.0)
	if session == null:
		draw_set_transform(Vector2.ZERO)
		return
	RCornerIndicators.paint(self,session.field,default_font)
	for e in session.field.enemies:
		var pos: Vector2 = e.pos
		var radius: float = maxf(6.0,float(e.size)*0.48)
		var color := RAccessibility.translate_color(Color(str(e.color)),int(session.options.get("color_mode",0)),bool(session.options.get("high_contrast",false)))
		if float(e.phase_time)>0.0:
			color.a = 0.35
		match str(e.shape):
			"circle": draw_circle(pos,radius,color)
			"square": draw_rect(Rect2(pos-Vector2.ONE*radius,Vector2.ONE*radius*2.0),color)
			"diamond": draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-radius),pos+Vector2(radius,0),pos+Vector2(0,radius),pos+Vector2(-radius,0)]),color)
			_: draw_colored_polygon(_polygon(pos,radius,_sides(str(e.shape))),color)
		RVfxStatus.paint(self,e)
	for hostile in session.field.hostile_projectiles:
		var pos: Vector2 = hostile.pos
		var tint: Color = Color("#ff5a70") if str(hostile.kind)=="boss_fan" else Color("#f5ac73")
		draw_colored_polygon(_polygon(pos,5.0,3),tint)
	for slot in session.train.cars.size():
		var car: Dictionary = session.train.cars[slot]
		var pos := session.train.position_for(slot)
		var facing := RCoachFormation.visual_facing(session.train.distance,slot,RBalance.START_SPEED*float(session.tree.stats().speed))
		var size_car := Vector2(30.0,20.0)
		var col := RAccessibility.translate_color(Color(str(car.get("color","#f8f9fa"))),int(session.options.get("color_mode",0)),bool(session.options.get("high_contrast",false)))
		if float(car.hp)<=0:
			col = Color("#4e5360")
		draw_set_transform(offset_world + pos*world_scale,facing,Vector2.ONE*world_scale)
		draw_rect(Rect2(-size_car*0.5,size_car),col)
		draw_rect(Rect2(-size_car*0.5,size_car),Color("#14202b"),false,1.2)
		draw_set_transform(offset_world,0.0,Vector2.ONE*world_scale)
	RVfxProjectiles.paint(self,session.weapons.projectiles)
	session.visuals.draw(self)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _sides(shape: String) -> int:
	match shape:
		"triangle":return 3
		"pentagon":return 5
		"hexagon":return 6
		"octagon":return 8
		"dodecagon":return 12
		_:return 4

func _polygon(center: Vector2,radius: float,sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for n in sides:
		pts.append(center + Vector2.from_angle(-PI*0.5+TAU*n/sides)*radius)
	return pts

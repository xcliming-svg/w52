class_name RVfxProjectiles
extends RefCounted

static func paint(canvas: CanvasItem, player_projectiles: Array[Dictionary]) -> void:
	for p in player_projectiles:
		var at: Vector2=p.pos
		match str(p.family):
			"frost":
				canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-7),at+Vector2(7,0),at+Vector2(0,7),at+Vector2(-7,0)]),Color("#87e9fc"))
			"rocket":
				canvas.draw_rect(Rect2(at-Vector2(6,6),Vector2(12,12)),Color("#fa715a"))
			"mortar":
				canvas.draw_rect(Rect2(at-Vector2(8,8),Vector2(16,16)),Color("#f6ad57"))
			"shotgun":
				canvas.draw_circle(at,2.5,Color("#ffe2a4"))
			"pistol":
				canvas.draw_rect(Rect2(at-Vector2(3,3),Vector2(6,6)),Color("#f2f8d5"))
			"gatling":
				canvas.draw_circle(at,2.0,Color("#fef2a6"))
			_:
				canvas.draw_rect(Rect2(at-Vector2(3,3),Vector2(6,6)),Color("#f2f8d5"))

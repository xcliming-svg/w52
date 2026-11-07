class_name RTreeRenderer
extends RefCounted

static func render(canvas: CanvasItem, session, area: Vector2, pan: Vector2, zoom: float, selected_id: String, filter_text: String, font: Font) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO,area),Color("#0b1820"))
	if session == null:
		return
	for row in session.registry.ordered_nodes:
		var node_id: String = str(row.id)
		if not session.tree.is_visible(node_id):
			continue
		var destination: Vector2 = RTreeCamera.to_screen(row,area,pan,zoom)
		for parent_id in row.get("requires",[]):
			if not session.tree.is_visible(str(parent_id)):
				continue
			var parent: Dictionary = session.registry.nodes.get(str(parent_id),{})
			if parent.is_empty():
				continue
			var origin: Vector2 = RTreeCamera.to_screen(parent,area,pan,zoom)
			canvas.draw_line(origin,destination,Color("#6cb49d") if session.tree.purchased.has(node_id) else Color("#536d66"),3.0,true)
	for row in session.registry.ordered_nodes:
		var node_id: String = str(row.id)
		if not session.tree.is_visible(node_id):
			continue
		var pos: Vector2 = RTreeCamera.to_screen(row,area,pan,zoom)
		var state: String = RTreePurchaseUI.state(session.tree,node_id)
		var tint: Color = Color(str(row.get("color","#e8f6eb")))
		if state == "unaffordable":
			tint = tint.darkened(0.35)
		elif state == "purchased":
			tint = tint.lightened(0.15)
		if not RTreeSearch.contains(row,filter_text):
			tint = tint.darkened(0.45)
		var radius: float = 18.0 if node_id == "C000" else 14.0
		canvas.draw_circle(pos,radius+2.0,Color("#172f2e"))
		canvas.draw_circle(pos,radius,tint)
		canvas.draw_arc(pos,radius+4.0,0.0,TAU,32,Color("#ffffff") if node_id==selected_id else (Color("#99e3ae") if state=="purchased" else Color("#2c5554")),2.2,true)
		if zoom >= 0.45 or node_id == selected_id:
			canvas.draw_string(font,pos+Vector2(-13.0,28.0),node_id,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e4f1ef"))
	canvas.draw_string(font,Vector2(16.0,27.0),"굴의 뿌리 · 연구할 가지를 누르세요",HORIZONTAL_ALIGNMENT_LEFT,maxi(0,int(area.x)-25),16,Color("#d5e4d9"))

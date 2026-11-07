class_name RTreeRenderer
extends RefCounted

static func render(canvas: CanvasItem, session, area: Vector2, pan: Vector2, zoom: float, selected_id: String, filter_text: String, font: Font) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO,area),Color("#0c1529"))
	if session==null:
		return
	for row in session.registry.ordered_nodes:
		var from: Vector2=RTreeCamera.to_screen(row,area,pan,zoom)
		for parent_id in row.get("requires",[]):
			var parent: Dictionary=session.registry.nodes.get(parent_id,{})
			if parent.is_empty():
				continue
			var to: Vector2=RTreeCamera.to_screen(parent,area,pan,zoom)
			var tint: Color=Color("#637592") if session.tree.purchased.has(str(parent_id)) else Color("#25334e")
			canvas.draw_line(from,to,tint,1.6,true)
	for row in session.registry.ordered_nodes:
		var id: String=str(row.id)
		var loc: Vector2=RTreeCamera.to_screen(row,area,pan,zoom)
		var state: String=RTreePurchaseUI.state(session.tree,id)
		var color: Color=Color(str(row.get("color","#f0f5ff"))) if state in ["purchased","available"] else Color("#45536e")
		if not RTreeSearch.contains(row,filter_text):
			color=color.darkened(0.75)
		var radius: float=18.0 if id=="C000" else 14.0
		canvas.draw_circle(loc,radius,color)
		var outline: Color=Color("#f8ffff") if id==selected_id else (Color("#86e8ad") if state=="purchased" else Color("#33465c"))
		canvas.draw_arc(loc,radius+3.5,0.0,TAU,20,outline,2.1,true)
		if zoom>=0.35 or id==selected_id:
			canvas.draw_string(font,loc+Vector2(-17.0,27.0),id,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e2ebf9"))
	var tooltip: String=RTreeTooltip.text_for(session.registry,session.tree,session.economy,selected_id)
	var rows: PackedStringArray=tooltip.split("\n")
	var ypos: float=26.0
	for text in rows:
		if ypos>area.y-12.0:
			break
		canvas.draw_string(font,Vector2(14.0,ypos),text,HORIZONTAL_ALIGNMENT_LEFT,maxi(0,int(area.x)-20),14,Color("#e4ebf7"))
		ypos+=23.0

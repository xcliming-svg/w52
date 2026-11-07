class_name RSpatialHash
extends RefCounted

const CELL_SIZE: float = 64.0
var cells: Dictionary = {}

func rebuild(entities: Array) -> void:
	cells.clear()
	for entity in entities:
		if str(entity.get("state","")) != "alive":
			continue
		var position: Vector2 = entity.pos
		var x: int = floori(position.x/CELL_SIZE)
		var y: int = floori(position.y/CELL_SIZE)
		var key := Vector2i(x,y)
		if not cells.has(key):
			cells[key] = []
		cells[key].append(entity)

func query(center: Vector2, radius: float) -> Array:
	var results: Array = []
	var min_x: int = floori((center.x-radius)/CELL_SIZE)
	var max_x: int = floori((center.x+radius)/CELL_SIZE)
	var min_y: int = floori((center.y-radius)/CELL_SIZE)
	var max_y: int = floori((center.y+radius)/CELL_SIZE)
	for x in range(min_x,max_x+1):
		for y in range(min_y,max_y+1):
			var key := Vector2i(x,y)
			if cells.has(key):
				for entity in cells[key]:
					results.append(entity)
	return results

func query_segment(from: Vector2, to: Vector2, padding: float) -> Array:
	var center: Vector2 = (from+to)*0.5
	var radius: float = from.distance_to(to)*0.5 + padding
	return query(center,radius)

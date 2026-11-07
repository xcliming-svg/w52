class_name RData
extends RefCounted

var nodes: Dictionary = {}
var wagons: Dictionary = {}
var enemies: Dictionary = {}
var ordered_nodes: Array = []
var ordered_wagons: Array = []
var ordered_enemies: Array = []
var error: String = ""

static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed := JSON.new()
	if parsed.parse(file.get_as_text()) != OK:
		return null
	return parsed.data

func load_all() -> bool:
	var tree: Variant = read_json("res://tree_nodes.json")
	var cars: Variant = read_json("res://wagons.json")
	var mobs: Variant = read_json("res://enemies.json")
	if not (tree is Dictionary and cars is Dictionary and mobs is Dictionary):
		error = "콘텐츠 JSON을 읽을 수 없습니다."
		return false
	ordered_nodes = tree.get("nodes", [])
	ordered_wagons = cars.get("cars", [])
	ordered_enemies = mobs.get("enemies", [])
	if ordered_nodes.size() != RBalance.TREE_NODES or ordered_wagons.size() != RBalance.WAGON_VARIANTS or ordered_enemies.size() != RBalance.ENEMY_VARIANTS:
		error = "콘텐츠 갯수가 CONTRACT.md와 다릅니다."
		return false
	for row in ordered_nodes:
		var id: String = str(row.get("id", ""))
		if id.is_empty() or nodes.has(id):
			error = "기술 노드 ID 중복/누락: " + id
			return false
		nodes[id] = row
	for row in ordered_wagons:
		var id: String = str(row.get("id", ""))
		if id.is_empty() or wagons.has(id):
			error = "객차 ID 중복/누락: " + id
			return false
		wagons[id] = row
	for row in ordered_enemies:
		var id: String = str(row.get("id", ""))
		if id.is_empty() or enemies.has(id):
			error = "적 ID 중복/누락: " + id
			return false
		enemies[id] = row
	for row in ordered_nodes:
		for required_id in row.get("requires", []):
			if not nodes.has(required_id):
				error = "선행 노드가 없습니다: " + str(required_id)
				return false
	if not nodes.has("C000"):
		error = "중앙 노드가 없습니다."
		return false
	return true

class_name RGameRng
extends RefCounted

var gameplay := RandomNumberGenerator.new()
var visuals := RandomNumberGenerator.new()

func start(seed_value: int) -> void:
	gameplay.seed = seed_value
	visuals.seed = (seed_value ^ 0x1F3B91A7) & 0x7FFFFFFFFFFFFFFF

func random_game() -> float:
	return gameplay.randf()

func range_game(a: float, b: float) -> float:
	return gameplay.randf_range(a, b)

func index_game(length: int) -> int:
	return gameplay.randi_range(0, maxi(0, length - 1))

func random_vfx() -> float:
	return visuals.randf()

func capture() -> Dictionary:
	return {"gameplay_state":str(gameplay.state),"visual_state":str(visuals.state),"seed":str(gameplay.seed)}

func restore(data: Dictionary) -> void:
	gameplay.seed = int(data.get("seed", 1))
	gameplay.state = int(data.get("gameplay_state", gameplay.state))
	visuals.state = int(data.get("visual_state", 1))

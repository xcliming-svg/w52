class_name RCollisionLayers
extends RefCounted

const TRAIN: int=1
const ENEMY: int=2
const WEAPON: int=4
const BOSS: int=8
const DECOR: int=16

static func combat_mask() -> int:
	return TRAIN|ENEMY|WEAPON|BOSS

static func decoration_is_combat(layer: int) -> bool:
	return (layer & combat_mask()) != 0 and (layer & DECOR)==0

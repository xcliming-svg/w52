class_name RAiSplitter
extends RefCounted

static func summon(field, enemy: Dictionary, template: Dictionary, rng: RGameRng) -> bool:
	if int(enemy.get("children",0)) >= 4 or float(enemy.get("timer",0.0)) > 0.0:
		return false
	enemy.children = int(enemy.children)+1
	enemy.timer = 8.0
	var where: Vector2 = Vector2(enemy.pos)+Vector2.from_angle(rng.range_game(0.0,TAU))*20.0
	return field.spawn(template,rng,int(enemy.target),where)

static func on_death(field, corpse: Dictionary, data: RData, rng: RGameRng, death_position: Vector2) -> int:
	if str(corpse.get("ai",""))!="split_on_death" or not data.enemies.has("EN01"):
		return 0
	var count: int=0
	for i in 2:
		var theta: float=rng.range_game(0.0,TAU)
		var where: Vector2=death_position+Vector2.from_angle(theta)*18.0
		if field.spawn(data.enemies["EN01"],rng,int(corpse.get("target",0)),where):
			count+=1
	return count

class_name REnemyContact
extends RefCounted

# Direct swept enemy-to-coach contact; both participants remain in gameplay arrays.
# Contact never creates a physics body, and the same enemy cannot hit every 60Hz tick.
const COOLDOWN_SECONDS: float = 0.9

static func hit_if_overlapping(enemy: Dictionary, previous: Vector2, train: RTrain, tree: RTreeRules, delta: float) -> bool:
	enemy.contact_cd=maxf(0.0,float(enemy.get("contact_cd",0.0))-delta)
	if str(enemy.get("state",""))!="alive" or float(enemy.contact_cd)>0.0:
		return false
	var kind: String=str(enemy.get("ai",""))
	# Explosive/artillery/boss attacks already use delayed hazards, not touch damage.
	if kind in ["detonate_near_rail","ranged_hull","boss_pattern"]:
		return false
	var damage: float=maxf(0.0,float(enemy.get("hull_damage",0.0)))
	if str(enemy.get("damage_type","escape"))!="hull":
		return false
	if damage<=0.0:
		return false
	var contact_radius: float=maxf(5.0,float(enemy.get("size",14.0))*0.45)+15.0
	var current: Vector2=Vector2(enemy.pos)
	var rail_distance: float=RRailPath.nearest_rail_position(current).distance_to(current)
	if rail_distance>contact_radius+float(enemy.get("speed",0.0))*delta:
		return false
	var closest_slot: int=-1
	var best_distance: float=INF
	for slot in train.active_count():
		var car: Dictionary=train.cars[slot]
		if float(car.get("hp",0.0))<=0.0:
			continue
		var at: Vector2=train.position_for(slot)
		if not RHitGeometry.intersects_circle(previous,current,at,contact_radius):
			continue
		var distance: float=at.distance_squared_to(current)
		if distance<best_distance:
			best_distance=distance
			closest_slot=slot
	if closest_slot<0:
		return false
	if closest_slot==0:
		train.take_hull_damage(damage,tree)
	else:
		train.take_wagon_damage(closest_slot,damage)
	enemy.contact_cd=COOLDOWN_SECONDS
	return true

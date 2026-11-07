class_name RMilestones
extends RefCounted

# Contract C07: each milestone is gated by its unique tree effect ID.
# Dynamic milestones are evaluated against the current run, not cached globally.

var leak_streak: int = 0
var leak_guard_cd: float = 0.0
var corner_slow_cd: float = 0.0
var emergency_fire_cd: float = 0.0
var emergency_fire_time: float = 0.0
var elite_claimed: bool = false
var scrap_recovery_cd: float = 0.0
var scorch_events: Dictionary = {}

func tick(delta: float, tree: RTreeRules, train: RTrain, field: REnemyField) -> void:
	leak_guard_cd = maxf(0.0,leak_guard_cd-delta)
	corner_slow_cd = maxf(0.0,corner_slow_cd-delta)
	emergency_fire_cd = maxf(0.0,emergency_fire_cd-delta)
	emergency_fire_time = maxf(0.0,emergency_fire_time-delta)
	scrap_recovery_cd = maxf(0.0,scrap_recovery_cd-delta)
	# F10: last 15% of an enemy's planned route, once per 25 seconds.
	if tree.has_milestone("F",10) and corner_slow_cd <= 0.0:
		for enemy in field.enemies:
			if str(enemy.state)=="alive" and Vector2(enemy.pos).distance_to(RBalance.CORNERS[int(enemy.target)]) <= 105.0:
				field.slow_enemy(int(enemy.uid),0.30,2.0)
				corner_slow_cd = 25.0
				break
	# R10: 2s emergency burst with global 12s cooldown.
	if tree.has_milestone("R",10) and emergency_fire_cd <= 0.0:
		for enemy in field.enemies:
			if str(enemy.state)=="alive" and Vector2(enemy.pos).distance_to(RBalance.CORNERS[int(enemy.target)]) < 125.0:
				emergency_fire_time = 2.0
				emergency_fire_cd = 12.0
				break

func active_fire_multiplier(tree: RTreeRules) -> float:
	return 1.20 if tree.has_milestone("R",10) and emergency_fire_time > 0.0 else 1.0

func modify_car_damage(tree: RTreeRules, train: RTrain, index: int) -> float:
	var multiplier: float = 1.0
	var car: Dictionary = train.cars[index]
	var neighbours: Array[Dictionary] = []
	for offset in [-1,1]:
		var other: int = index + int(offset)
		if other>=1 and other<train.cars.size():
			neighbours.append(train.cars[other])
	if tree.has_milestone("W",4):
		for near in neighbours:
			if str(near.family)==str(car.family):
				multiplier += 0.03
				break
	if tree.has_milestone("S",4):
		for near in neighbours:
			if str(near.get("role",""))!=str(car.get("role","")):
				multiplier += 0.03
				break
	if tree.has_milestone("S",7) and neighbours.size()==2:
		var roles: Dictionary = {str(car.get("role","")):true}
		for near in neighbours:
			roles[str(near.get("role",""))]=true
		if roles.size()==3:
			multiplier += 0.06
	if tree.has_milestone("S",10):
		multiplier = minf(1.72,multiplier)
	return multiplier

func modify_car_priority(tree: RTreeRules, slot: int, number_cars: int, desired: String) -> String:
	if tree.has_milestone("W",7):
		return "elite" if slot < number_cars/2 else "escape"
	if tree.has_milestone("L",7):
		return "escape"
	return desired

func modify_car_cycle(tree: RTreeRules, car: Dictionary, base: float) -> float:
	var adjusted: float = base / active_fire_multiplier(tree)
	if tree.has_milestone("R",7) and float(car.get("continuous_fire",0.0))>8.0:
		adjusted *= 1.04
	if tree.has_milestone("S",10):
		adjusted *= 1.03
	return adjusted

func expected_shots(tree: RTreeRules) -> int:
	return 3 if tree.has_milestone("R",4) else 1

func chain_links(tree: RTreeRules) -> int:
	if tree.has_milestone("C",10):
		return 3
	if tree.has_milestone("C",7):
		return 2
	if tree.has_milestone("C",4):
		return 1
	return 0

func pierce_targets(tree: RTreeRules) -> int:
	if tree.has_milestone("P",10):
		return 4
	if tree.has_milestone("P",7):
		return 3
	if tree.has_milestone("P",4):
		return 2
	return 1

func pierce_scale(tree: RTreeRules, index: int) -> float:
	if index <= 0:
		return 1.0
	if index == 1 and tree.has_milestone("P",4):
		return 0.75
	if index == 2 and tree.has_milestone("P",7):
		return 0.55
	if index == 3 and tree.has_milestone("P",10):
		return 0.42
	return 0.0

func blast_radius(tree: RTreeRules, radius: float) -> float:
	return radius * (1.10 if tree.has_milestone("X",4) else 1.0)

func blast_edge_falloff(tree: RTreeRules) -> float:
	return 0.30 if tree.has_milestone("X",7) else 0.40

func blast_fragments(tree: RTreeRules) -> int:
	return 6 if tree.has_milestone("X",10) else 0

func fire_duration(tree: RTreeRules, enemy_is_boss: bool) -> float:
	var time: float = 1.6
	if tree.has_milestone("H",4):
		time += 0.45
	# F04 applies to frost freeze, not to burn damage duration.
	return time

func burn_echo_scale(tree: RTreeRules) -> float:
	return 0.60 if tree.has_milestone("H",7) else 0.0

func burn_spread_count(tree: RTreeRules) -> int:
	return 3 if tree.has_milestone("H",10) else 0

func frost_slow(tree: RTreeRules, burning: bool) -> float:
	var slow := 0.45
	if burning and tree.has_milestone("F",7):
		slow += 0.10
	return slow

func mitigation_for_collision(tree: RTreeRules) -> float:
	return 0.85 if tree.has_milestone("A",4) else 1.0

func allow_leak(tree: RTreeRules) -> bool:
	leak_streak += 1
	if tree.has_milestone("A",10) and leak_streak>=3 and leak_guard_cd<=0.0:
		leak_streak=0
		leak_guard_cd=120.0
		return false
	return true

func on_enemy_kill(tree: RTreeRules, reward: float) -> Dictionary:
	var elite_bonus := false
	if tree.has_milestone("E",7) and reward>=4.0 and not elite_claimed:
		elite_bonus = true
		elite_claimed = true
	return {"elite_bonus":elite_bonus,"burn_echo":burn_echo_scale(tree),"burn_spread":burn_spread_count(tree),"frag_count":blast_fragments(tree)}

func on_scrap_spent(tree: RTreeRules, spent: float) -> float:
	if tree.has_milestone("E",10) and spent>0.0 and scrap_recovery_cd<=0.0:
		scrap_recovery_cd=60.0
		return spent * 0.10
	return 0.0

func bonus_scrap_multiplier(tree: RTreeRules) -> float:
	return 1.03 if tree.has_milestone("E",4) else 1.0

func speed_multiplier(tree: RTreeRules, head_distance: float) -> float:
	var speed: float = 1.10 if tree.has_milestone("L",10) else 1.0
	var dist: float = RBalance.positive_mod(head_distance,RBalance.PERIMETER)
	var next_corner: float = 1175.0 if dist<1175.0 else (1950.0 if dist<1950.0 else (3125.0 if dist<3125.0 else 3900.0))
	if next_corner - dist < 10.0:
		speed *= 0.98 if tree.has_milestone("L",4) else 0.96
	return speed

func crit_guaranteed(tree: RTreeRules, enemy: Dictionary, tick: int) -> bool:
	if not tree.has_milestone("U",10):
		return false
	var count: int = int(enemy.get("hit_count",0))
	var last_tick: int = int(enemy.get("crit_cooldown_tick",-360))
	return count>0 and count%8==0 and tick-last_tick>=6*RBalance.TICK_RATE

func snapshot() -> Dictionary:
	return {"leak_streak":leak_streak,"leak_guard_cd":leak_guard_cd,"corner_slow_cd":corner_slow_cd,"emergency_fire_cd":emergency_fire_cd,"emergency_fire_time":emergency_fire_time,"elite_claimed":elite_claimed,"scrap_recovery_cd":scrap_recovery_cd}

func restore(s: Dictionary) -> void:
	leak_streak=int(s.get("leak_streak",0))
	leak_guard_cd=float(s.get("leak_guard_cd",0.0))
	corner_slow_cd=float(s.get("corner_slow_cd",0.0))
	emergency_fire_cd=float(s.get("emergency_fire_cd",0.0))
	emergency_fire_time=float(s.get("emergency_fire_time",0.0))
	elite_claimed=bool(s.get("elite_claimed",false))
	scrap_recovery_cd=float(s.get("scrap_recovery_cd",0.0))

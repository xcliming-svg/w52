class_name RWeaponSystem
extends RefCounted

const PROJECTILE_SYSTEM := preload("res://scripts/projectile_system.gd")
const GUN_PISTOL := preload("res://scripts/gun_pistol.gd")
const GUN_GATLING := preload("res://scripts/gun_gatling.gd")
const GUN_SHOTGUN := preload("res://scripts/gun_shotgun.gd")
const GUN_SNIPER := preload("res://scripts/gun_sniper.gd")
const GUN_MORTAR := preload("res://scripts/gun_mortar.gd")
const GUN_ROCKET := preload("res://scripts/gun_rocket.gd")
const GUN_BLADE := preload("res://scripts/gun_blade.gd")
const GUN_FLAME := preload("res://scripts/gun_flame.gd")
const GUN_FROST := preload("res://scripts/gun_frost.gd")
const GUN_TESLA := preload("res://scripts/gun_tesla.gd")
const GUN_SUPPORT := preload("res://scripts/gun_support.gd")
const GUN_SHOCKWAVE := preload("res://scripts/gun_shockwave.gd")

signal weapon_fired(family: String, origin: Vector2, end: Vector2)
signal blast(origin: Vector2, radius: float, family: String)

var milestones
var projectiles: Array[Dictionary] = []
var spatial := RSpatialHash.new()
var pool := REntityPool.new()
var serial: int = 1
var shot_counters: Dictionary = {}
var sound_group: Dictionary = {}
var hit_events: int = 0
var current_tick: int = 0
var fragment_budget: int = 12
var active_car: Dictionary = {}

func initialize() -> void:
	projectiles.clear()
	pool.clear()
	spatial.cells.clear()
	serial = 1
	shot_counters.clear()
	hit_events = 0

func _next_hit() -> String:
	var hit: String = "shot:%d" % serial
	serial += 1
	return hit

func _has_arc(train: RTrain, slot: int, target: Vector2) -> bool:
	var center: Vector2 = train.position_for(slot)
	var facing: Vector2 = Vector2.from_angle(RRailPath.heading(train.distance - slot * RBalance.RAIL_SPACING) + PI * 0.5)
	return facing.dot((target-center).normalized()) > -0.20

func _find_target(train: RTrain, slot: int, field: REnemyField, max_range: float, priority: String = "escape") -> Dictionary:
	var origin: Vector2 = train.position_for(slot)
	var facing: Vector2 = Vector2.from_angle(RRailPath.heading(train.distance-float(slot)*RBalance.RAIL_SPACING)+PI*0.5)
	return RTargetSelector.best(spatial.query(origin,max_range+40.0),origin,max_range,priority,facing)

func step(delta: float, train: RTrain, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	fragment_budget = 12
	spatial.rebuild(field.enemies)
	_projectiles_tick(delta, field, tree, rng)
	var mods: Dictionary = tree.stats()
	for slot in train.cars.size():
		var car: Dictionary = train.cars[slot]
		if not RWeaponBase.can_fire(car):
			continue
		active_car=car
		var family: String = str(car.family)
		if family == "support":
			GUN_SUPPORT.fire(self,train,slot,car)
			weapon_fired.emit("support",train.position_for(slot),train.position_for(slot))
			continue
		var base_range: float = 145.0
		match family:
			"sniper":base_range = 700.0
			"mortar":base_range = 530.0
			"rocket":base_range = 425.0
			"tesla":base_range = 330.0
			"frost":base_range = 310.0
			"blade":base_range = 108.0
			"flame":base_range = 135.0
			"shockwave":base_range = 116.0
			"shotgun":base_range = 185.0
			_:base_range = 260.0
		var priority: String = str(car.get("aim", "escape"))
		if milestones != null:
			priority = milestones.modify_car_priority(tree,slot,train.cars.size(),priority)
		var target: Dictionary = _find_target(train, slot, field, base_range * float(mods.range)*(1.0+float(car.get("range_bonus",0.0))), priority)
		if target.is_empty():
			continue
		var origin := train.position_for(slot)
		var target_pos: Vector2 = target.pos
		var cycle: float = RWeaponBase.cycle(car,float(mods.fire_rate))
		if family == "gatling":
			var heat := float(car.heat)
			cycle *= 1.0 + heat * (0.08 if tree.has_milestone("R",7) else 0.18)
			car.heat = minf(5.0, heat + 0.20)
		car.continuous_fire = float(car.get("continuous_fire",0.0)) + cycle
		if milestones != null:
			cycle = milestones.modify_car_cycle(tree,car,cycle)
		car.cd = cycle
		var base_damage: float = RWeaponBase.base_hit(car,float(mods.damage))
		if milestones != null:
			base_damage *= milestones.modify_car_damage(tree,train,slot)
		if str(target.ai)=="boss_pattern":
			base_damage*=1.0+float(car.get("boss_bonus",0.0))
		var shot_count: int = milestones.expected_shots(tree) if milestones != null else 1
		for sub in shot_count:
			var damage: float = base_damage / shot_count
			match family:
				"pistol": GUN_PISTOL.fire(self,origin,target,damage,field,tree,rng)
				"gatling": GUN_GATLING.fire(self,origin,target,damage,field,tree,rng)
				"shotgun": GUN_SHOTGUN.fire(self,origin,target,damage,field,tree,rng)
				"sniper": GUN_SNIPER.fire(self,origin,target,damage,field,tree,rng)
				"mortar": GUN_MORTAR.fire(self,origin,target,damage,field,tree,rng)
				"rocket": GUN_ROCKET.fire(self,origin,target,damage,field,tree,rng)
				"blade": GUN_BLADE.fire(self,origin,target,damage,field,tree,rng)
				"flame": GUN_FLAME.fire(self,origin,target,damage,field,tree,rng)
				"frost": GUN_FROST.fire(self,origin,target,damage,field,tree,rng)
				"tesla": GUN_TESLA.fire(self,origin,target,damage,field,tree,rng)
				"shockwave": GUN_SHOCKWAVE.fire(self,origin,target,damage,field,tree,rng)
			weapon_fired.emit(family, origin, target_pos)

func _critical(base: float, tree: RTreeRules, rng: RGameRng) -> Dictionary:
	var st: Dictionary = tree.stats()
	return RDamagePipeline.resolve(base,0.0,1.0,1.0,float(st.crit_chance),float(st.crit_multiplier),rng)

func _direct_hit(field: REnemyField, id: int, base: float, kind: String, unique_id: String, tree: RTreeRules, rng: RGameRng, crit_override: bool = false) -> float:
	var roll: Dictionary = _critical(base, tree, rng)
	var target: Dictionary = field.by_id(id)
	var guaranteed: bool = milestones != null and not target.is_empty() and milestones.crit_guaranteed(tree,target,current_tick)
	var critical: bool = bool(roll.critical) or crit_override or guaranteed
	var final_damage: float = float(roll.damage)
	if (guaranteed or crit_override) and not bool(roll.critical):
		final_damage *= float(tree.stats().crit_multiplier)
	var applied_damage: float=field.apply_damage(id,final_damage,kind,unique_id,critical)
	if guaranteed and applied_damage>0.0:
		target.crit_cooldown_tick=current_tick
	return applied_damage

func _emit_projectile(family: String, origin: Vector2, end: Vector2, target_id: int, damage: float, speed: float, rng: RGameRng, tree: RTreeRules) -> void:
	if projectiles.size() >= RBalance.max_projectiles():
		return
	var direction: Vector2 = (end-origin).normalized()
	var id := _next_hit()
	var projectile: Dictionary = pool.acquire()
	projectile.merge({"id":id,"family":family,"pos":origin,"velocity":direction*speed,"target":target_id,"damage":damage,"age":0.0,"ttl":3.5,"hits":{},"pierce":maxi(0,milestones.pierce_targets(tree)-1) if family == "pistol" and milestones != null else 0,"radius":10.0,"aoe_radius":65.0*(1.0+float(active_car.get("aoe_bonus",0.0)))},true)
	projectiles.append(projectile)

func _shotgun(origin: Vector2, target: Vector2, damage: float, rng: RGameRng, tree: RTreeRules) -> void:
	for k in 5:
		var theta: float = (target-origin).angle() + (float(k)-2.0) * 0.125
		_emit_projectile("shotgun", origin, origin + Vector2.from_angle(theta)*300.0, -1, damage * 0.2, 440.0, rng, tree)

func _sniper(origin: Vector2, target: Vector2, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var dir: Vector2 = (target-origin).normalized()
	var far: Vector2 = origin + dir * 760.0
	var candidates: Array[Dictionary] = []
	for enemy in field.enemies:
		if str(enemy.state) == "alive" and _segment_distance(Vector2(enemy.pos), origin, far) <= float(enemy.size)*0.5 + 4.0:
			candidates.append(enemy)
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return origin.distance_squared_to(a.pos) < origin.distance_squared_to(b.pos))
	var penetrations: int = mini(4,(milestones.pierce_targets(tree) if milestones != null else 1)+int(active_car.get("pierce_bonus",0)))
	var uid: String = _next_hit()
	for j in mini(penetrations, candidates.size()):
		var attenuation: float = milestones.pierce_scale(tree,j) if milestones != null else pow(0.75,float(j))
		var dealt: float=_direct_hit(field,int(candidates[j].uid),damage * attenuation,"kinetic",uid,tree,rng)
		if dealt>0.0:
			RStatusArmorBreak.apply_break(candidates[j],0.15,2.5)
	blast.emit(origin, 7.0, "sniper")

func _mortar(origin: Vector2, target: Vector2, damage: float, tree: RTreeRules) -> void:
	if projectiles.size() >= RBalance.max_projectiles():
		return
	var uid := _next_hit()
	var projectile: Dictionary = pool.acquire()
	projectile.merge({"id":uid,"family":"mortar","pos":origin,"start":origin,"impact":target,"velocity":Vector2.ZERO,"target":-1,"damage":damage,"age":0.0,"ttl":0.75,"hits":{},"radius":60.0 * float(tree.stats().aoe)*(1.0+float(active_car.get("aoe_bonus",0.0)))},true)
	projectiles.append(projectile)
	blast.emit(target, 63.0, "warning")

func _melee(family: String, origin: Vector2, toward: Vector2, damage: float, radius: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var id := _next_hit()
	var facing := (toward-origin).normalized()
	for e in field.enemies:
		var delta: Vector2 = Vector2(e.pos)-origin
		if str(e.state) == "alive" and delta.length() <= radius and delta.normalized().dot(facing) > 0.3:
			_direct_hit(field,int(e.uid),damage,"kinetic",id,tree,rng)
	blast.emit(origin, radius, family)

func _flame(origin: Vector2, toward: Vector2, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var id := _next_hit()
	var facing: Vector2 = (toward-origin).normalized()
	for e in field.enemies:
		var diff: Vector2 = Vector2(e.pos)-origin
		if str(e.state) == "alive" and diff.length() < 135.0 and diff.normalized().dot(facing) >= 0.65:
			var dealt := _direct_hit(field,int(e.uid),damage*0.25,"fire",id,tree,rng)
			if dealt > 0.0:
				var seconds: float=milestones.fire_duration(tree,str(e.ai)=="boss_pattern") if milestones!=null else 1.6
				field.add_burn(int(e.uid),damage * 0.7*(1.0+float(active_car.get("dot_bonus",0.0))),seconds)
	blast.emit(origin, 110.0, "flame")

func _tesla(origin: Vector2, first: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var id := _next_hit()
	var hit: Dictionary = {}
	var victim: Dictionary = first
	var count: int = mini(4,1 + (milestones.chain_links(tree) if milestones != null else 0)+int(active_car.get("chain_bonus",0)))
	for hop in count:
		if victim.is_empty():
			break
		var victim_id: int = int(victim.uid)
		hit[victim_id] = true
		_direct_hit(field,victim_id,damage * pow(0.75,float(hop)),"electric",id,tree,rng)
		blast.emit(Vector2(victim.pos), 20.0, "tesla")
		victim = RStatusChain.next_target(victim,spatial.query(Vector2(victim.pos),165.0),hit,165.0)

func _shockwave(origin: Vector2, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var id := _next_hit()
	for e in field.enemies:
		var away: Vector2 = Vector2(e.pos)-origin
		if str(e.state) == "alive" and away.length() < 116.0:
			_direct_hit(field,int(e.uid),damage,"kinetic",id,tree,rng)
			e.pos = Vector2(e.pos) + away.normalized() * 32.0*(1.0+float(active_car.get("knockback_bonus",0.0)))
	blast.emit(origin, 116.0, "shockwave")

func _support(train: RTrain, slot: int, car: Dictionary) -> void:
	for offset in [-1, 1]:
		var other: int = slot + int(offset)
		if other >= 0 and other < train.cars.size() and other != slot and str(train.cars[other].family) != "support":
			train.cars[other].shield = minf(20.0, float(train.cars[other].get("shield",0.0)) + 4.0)
			train.cars[other].cd = maxf(0.0, float(train.cars[other].cd) - 0.05)
	car.cd = float(car.get("cycleSeconds",0.5))
	blast.emit(train.position_for(slot), 34.0, "support")

func _projectiles_tick(delta: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	PROJECTILE_SYSTEM.advance(self,delta,field,tree,rng)

func _explode(center: Vector2, radius: float, damage: float, family: String, id: String, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var actual_radius: float = milestones.blast_radius(tree,radius) if milestones != null else radius
	for enemy in spatial.query(center,actual_radius+40.0):
		if str(enemy.state) != "alive":
			continue
		var dist := Vector2(enemy.pos).distance_to(center)
		if dist <= actual_radius:
			var falloff: float = milestones.blast_edge_falloff(tree) if milestones != null else 0.4
			_direct_hit(field,int(enemy.uid),damage * (1.0 - falloff * dist / maxf(1.0,actual_radius)), "fire", id, tree, rng)
	blast.emit(center,radius,family)

func fragment_blast(center: Vector2, count: int, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var generated: int = mini(fragment_budget,mini(count,6))
	fragment_budget -= generated
	for i in generated:
		var hit_id: String = _next_hit()
		var angle: float = TAU * float(i) / float(generated)
		var target: Vector2 = center + Vector2.from_angle(angle) * 65.0
		for e in spatial.query_segment(center,target,10.0):
			if str(e.state)=="alive" and RHitGeometry.intersects_circle(center,target,Vector2(e.pos),float(e.size)*0.5):
				_direct_hit(field,int(e.uid),3.0,"kinetic",hit_id,tree,rng)
		blast.emit(target,6.0,"fragment")

func burn_death_echo(center: Vector2, scale: float, spread_count: int, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var applied: int = 0
	for e in spatial.query(center,150.0):
		if applied >= maxi(1,spread_count):
			break
		if str(e.state)=="alive" and Vector2(e.pos).distance_to(center) <= (80.0 if spread_count>0 else 30.0):
			var dealt := _direct_hit(field,int(e.uid),4.0*scale,"fire",_next_hit(),tree,rng)
			if dealt>0.0:
				field.add_burn(int(e.uid),4.0*scale,0.7)
				applied += 1
	blast.emit(center,65.0,"flame")

func _closest_enemy(origin: Vector2, field: REnemyField, radius: float) -> Dictionary:
	var best := radius
	var chosen: Dictionary = {}
	for enemy in field.enemies:
		if str(enemy.state) != "alive":
			continue
		var dis: float = Vector2(enemy.pos).distance_to(origin)
		if dis < best:
			best = dis
			chosen = enemy
	return chosen

static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	return RHitGeometry.segment_distance(p,a,b)

func snapshot() -> Dictionary:
	var packed: Array = []
	for projectile in projectiles:
		var copy: Dictionary = projectile.duplicate(true)
		for field_name in ["pos","start","impact","velocity"]:
			if copy.has(field_name):
				var v: Vector2 = copy[field_name]
				copy[field_name] = [v.x,v.y]
		packed.append(copy)
	return {"projectiles":packed,"serial":serial}

func restore(s: Dictionary) -> void:
	projectiles.clear()
	for item in s.get("projectiles", []):
		var p: Dictionary = item.duplicate(true)
		for key in ["pos","start","impact","velocity"]:
			if p.has(key):
				var raw: Array = p[key]
				p[key] = Vector2(float(raw[0]),float(raw[1]))
		projectiles.append(p)
	serial = int(s.get("serial",1))

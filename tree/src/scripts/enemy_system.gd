class_name REnemyField
extends RefCounted

signal enemy_damaged(id: int, amount: float, position: Vector2, damage_type: String, critical: bool)
signal enemy_killed(id: int, position: Vector2, reward: float, family: String)
signal enemy_escaped(id: int, corner: int, amount: float)
signal battlefield_loss(reason: String)
signal enemy_warning(text: String, position: Vector2)

var milestones
var enemies: Array[Dictionary] = []
var pool := REntityPool.new()
var templates: Array = []
var next_id: int = 1
var spawn_credit: float = 0.0
var elapsed: float = 0.0
var barrier: float = RBalance.BARRIER_MAX
var escaped_count: int = 0
var killed_count: int = 0
var last_boss_minute: int = 0
var pending_boss: float = -1.0
var pending_boss_minute: int = 0
var collision_cache: Dictionary = {}
var danger_cooldown: float = 0.0
var invulnerability: Dictionary = {}
var recent_deaths: Dictionary = {}
var hostile_projectiles: Array[Dictionary] = []
var hazard_serial: int = 1

func initialize(data: RData) -> void:
	templates = data.ordered_enemies
	enemies.clear()
	pool.clear()
	next_id = 1
	spawn_credit = 0.0
	elapsed = 0.0
	barrier = RBalance.BARRIER_MAX
	escaped_count = 0
	killed_count = 0
	last_boss_minute = 0
	pending_boss = -1.0
	pending_boss_minute = 0
	collision_cache.clear()
	recent_deaths.clear()
	hostile_projectiles.clear()
	hazard_serial = 1

func spawn(spec: Dictionary, rng: RGameRng, corner_override: int = -1, position_override: Vector2 = Vector2.INF) -> bool:
	if enemies.size() >= RBalance.max_entities():
		return false
	var id: int = next_id
	next_id += 1
	var where: Vector2 = position_override
	if not where.is_finite():
		var radius: float = rng.range_game(12.0,30.0)
		var angle: float = rng.range_game(0.0,TAU)
		where = RBalance.CENTER + Vector2.from_angle(angle)*radius
	var corner: int = corner_override if corner_override>=0 else RCornerTargeting.uniform_corner(rng)
	var instance: Dictionary = REnemyFactory.create(spec,id,elapsed,where,corner)
	if str(instance.ai)=="boss_pattern":
		enemy_warning.emit(RAiElite.pattern_warning(0),where)
	var recycled: Dictionary=pool.acquire()
	recycled.merge(instance,true)
	enemies.append(recycled)
	return true

func _spawn_schedule(delta: float, rng: RGameRng) -> void:
	spawn_credit = RSpawnDirector.accrue(spawn_credit,elapsed,delta,rng)
	var count := 0
	while spawn_credit >= 1.0 and count < RSpawnDirector.spawn_limit_per_tick():
		var index: int = RSpawnDirector.regular_template_index(rng,templates.size())
		spawn(templates[index], rng)
		spawn_credit -= 1.0
		count += 1
	# Warn 15 seconds BEFORE each five-minute elite/boss wave.
	var minute_int := RSpawnDirector.warn_minute(elapsed)
	if RSpawnDirector.due(minute_int,last_boss_minute):
		last_boss_minute = minute_int
		pending_boss = 15.0
		pending_boss_minute = minute_int
		enemy_warning.emit("15초 후 정예·보스 등장", RBalance.CENTER)
	if pending_boss >= 0.0:
		pending_boss -= delta
		if pending_boss < 0.0:
			spawn(templates[13], rng)
			for j in 3:
				spawn(templates[12], rng)

func step(delta: float, train: RTrain, tree: RTreeRules, rng: RGameRng) -> void:
	elapsed += delta
	danger_cooldown = maxf(0.0, danger_cooldown - delta)
	_spawn_schedule(delta, rng)
	var expired: Array[int] = []
	for enemy in enemies:
		if str(enemy.state) != "alive":
			expired.append(int(enemy.uid))
			continue
		enemy.elapsed = float(enemy.elapsed) + delta
		enemy.timer = maxf(0.0, float(enemy.timer) - delta)
		var previous_impact_cd: float = float(enemy.impact_cd)
		enemy.impact_cd = maxf(0.0, float(enemy.impact_cd) - delta)
		RStatusCold.release(enemy,delta)
		RStatusArmorBreak.tick(enemy,delta)
		_apply_burn(enemy, delta)
		if str(enemy.state) != "alive":
			expired.append(int(enemy.uid))
			continue
		var previous_position: Vector2=Vector2(enemy.pos)
		var target: Vector2 = RCornerTargeting.corner_position(int(enemy.target))
		var move_dir: Vector2 = (target - Vector2(enemy.pos)).normalized()
		var speed_scale: float = 0.0 if float(enemy.frozen_time)>0.0 else 1.0 - float(enemy.slow)
		if RAiRunner.dash_telegraph(enemy,delta):
			enemy_warning.emit("도약 돌진 예고",Vector2(enemy.pos))
		var steering: Dictionary = RAiRunner.steering(enemy,move_dir,delta)
		move_dir = steering.heading
		speed_scale *= float(steering.speed)
		match str(enemy.ai):
			"blink","absorb_projectile":
				RAiPhase.tick(enemy,delta)
			"summon_minions":
				RAiSplitter.summon(self,enemy,templates[0],rng)
			"slow_train":
				RAiSlowTrain.influence(enemy,train)
			"ranged_hull":
				if RAiArtillery.should_telegraph(enemy):
					RAiArtillery.begin_attack(enemy,train,rng,func(message: String, where: Vector2) -> void: enemy_warning.emit(message,where))
			"boss_pattern":
				_step_boss(enemy,delta,train,tree,rng)
		if str(enemy.ai) == "ranged_hull" and RAiArtillery.is_ready(previous_impact_cd,float(enemy.impact_cd)):
			var locked_target: Vector2 = RAiArtillery.locked_target(enemy,train)
			_fire_hazard(Vector2(enemy.pos),locked_target,float(enemy.hull_damage),"artillery")
		if str(enemy.ai) == "detonate_near_rail":
			if RAiSuicide.tick(enemy,delta,train,tree,func(message: String, where: Vector2) -> void: enemy_warning.emit(message,where)):
				enemy.state = "dying"
				expired.append(int(enemy.uid))
				continue
		REnemyMotion.advance(enemy,move_dir,speed_scale,delta)
		REnemyContact.hit_if_overlapping(enemy,previous_position,train,tree,delta)
		enemy.phase_time = maxf(0.0, float(enemy.phase_time) - delta)
		if REnemyMotion.has_escaped(enemy):
			REnemyLifecycle.mark_escaped(enemy)
			escaped_count += 1
			var loss := float(enemy.escape_damage) * float(tree.stats().escape_reduction)
			if milestones != null and not milestones.allow_leak(tree):
				loss = 0.0
			barrier = maxf(0.0, barrier - loss)
			enemy_escaped.emit(int(enemy.uid), int(enemy.target), loss)
			expired.append(int(enemy.uid))
			if barrier <= 0.0:
				battlefield_loss.emit("방벽 붕괴")
	_step_hazards(delta,train,tree)
	if not expired.is_empty():
		var dead: Dictionary = {}
		for uid in expired:
			dead[uid] = true
		for i in range(enemies.size()-1, -1, -1):
			if dead.has(int(enemies[i].uid)):
				REnemyLifecycle.finalize(enemies[i])
				pool.recycle(enemies[i])
				enemies.remove_at(i)

func _step_boss(enemy: Dictionary, delta: float, train: RTrain, tree: RTreeRules, rng: RGameRng) -> void:
	RBossController.tick(enemy,self,train,tree,rng,func(message: String, where: Vector2) -> void: enemy_warning.emit(message,where))


func _fire_hazard(from: Vector2, target: Vector2, damage: float, kind: String) -> void:
	if hostile_projectiles.size() >= 256:
		return
	var delta: Vector2 = target-from
	if delta.length_squared()<0.01:
		return
	var speed: float = 230.0 if kind=="boss_fan" else 195.0
	hostile_projectiles.append({"uid":hazard_serial,"pos":from,"vel":delta.normalized()*speed,"target":target,"age":0.0,"ttl":4.0,"damage":damage,"kind":kind})
	hazard_serial+=1

func _step_hazards(delta: float, train: RTrain, tree: RTreeRules) -> void:
	for i in range(hostile_projectiles.size()-1,-1,-1):
		var hazard: Dictionary = hostile_projectiles[i]
		var previous: Vector2 = hazard.pos
		hazard.pos = Vector2(hazard.pos)+Vector2(hazard.vel)*delta
		hazard.age = float(hazard.age)+delta
		var impacted: bool = false
		for j in train.active_count():
			if float(train.cars[j].hp)<=0.0:
				continue
			if RHitGeometry.intersects_circle(previous,Vector2(hazard.pos),train.position_for(j),16.0):
				if j==0:
					train.take_hull_damage(float(hazard.damage),tree)
				else:
					train.take_wagon_damage(j,float(hazard.damage))
				impacted=true
				break
		if float(hazard.age)>float(hazard.ttl) or impacted:
			hostile_projectiles.remove_at(i)

func _explode_on_rail(position: Vector2, damage: float, train: RTrain, tree: RTreeRules) -> void:
	for j in train.active_count():
		if float(train.cars[j].hp)>0.0 and train.position_for(j).distance_to(position)<60.0:
			if j==0:
				train.take_hull_damage(damage,tree)
			else:
				train.take_wagon_damage(j,damage)

func _apply_burn(enemy: Dictionary, delta: float) -> void:
	RStatusDot.tick(enemy,delta,self,int(elapsed*RBalance.TICK_RATE))


func add_burn(id: int, power: float, seconds: float) -> void:
	var enemy: Dictionary=by_id(id)
	if not enemy.is_empty():
		RStatusDot.add(enemy,power,seconds)


func slow_enemy(id: int, factor: float, seconds: float) -> void:
	var enemy: Dictionary=by_id(id)
	if not enemy.is_empty():
		RStatusCold.apply_slow(enemy,factor,seconds)

func freeze_enemy(id: int, seconds: float) -> void:
	var enemy: Dictionary=by_id(id)
	if not enemy.is_empty():
		RStatusCold.apply_freeze(enemy,seconds)


func by_id(id: int) -> Dictionary:
	for e in enemies:
		if int(e.uid) == id and str(e.state) == "alive":
			return e
	return {}

func apply_damage(id: int, amount: float, kind: String, unique_hit: String, critical: bool) -> float:
	var enemy: Dictionary=by_id(id)
	if enemy.is_empty() or not REnemyLifecycle.can_hit(enemy,unique_hit):
		return 0.0
	if not RHitEventDedup.accept(enemy,unique_hit):
		return 0.0
	var adjusted: float=RDefenseResists.mitigate(enemy,amount,kind)
	var absorbed: float=minf(adjusted,float(enemy.shield))
	enemy.shield=maxf(0.0,float(enemy.shield)-absorbed)
	adjusted-=absorbed
	enemy.hp=maxf(0.0,float(enemy.hp)-adjusted)
	enemy.hit_count=int(enemy.get("hit_count",0))+1
	if adjusted>0.0:
		enemy_damaged.emit(id,adjusted,Vector2(enemy.pos),kind,critical)
	if float(enemy.hp)<=0.0 and REnemyLifecycle.mark_dying(enemy):
		recent_deaths[id]={"burning":not enemy.burn.is_empty(),"position":Vector2(enemy.pos),"ai":str(enemy.ai),"target":int(enemy.target)}
		if recent_deaths.size()>100:
			recent_deaths.erase(recent_deaths.keys()[0])
		killed_count+=1
		enemy_killed.emit(id,Vector2(enemy.pos),float(enemy.reward),str(enemy.kind))
	return adjusted

func snapshot() -> Dictionary:
	var packed: Array = []
	for e in enemies:
		var copy: Dictionary = e.duplicate(true)
		copy.pos = [e.pos.x, e.pos.y]
		if e.has("artillery_target"):
			var aim: Vector2 = e.artillery_target
			copy.artillery_target = [aim.x,aim.y]
		packed.append(copy)
	return {"enemies":packed,"next_id":next_id,"spawn_credit":spawn_credit,"elapsed":elapsed,"barrier":barrier,"escaped_count":escaped_count,"killed_count":killed_count,"last_boss_minute":last_boss_minute,"pending_boss":pending_boss,"pending_boss_minute":pending_boss_minute,"hostile_projectiles":_pack_hazards(),"hazard_serial":hazard_serial}

func _pack_hazards() -> Array:
	var packed: Array = []
	for hazard in hostile_projectiles:
		var h: Dictionary = hazard.duplicate(true)
		h.pos = [hazard.pos.x,hazard.pos.y]
		h.vel = [hazard.vel.x,hazard.vel.y]
		h.target = [hazard.target.x,hazard.target.y]
		packed.append(h)
	return packed

func restore(s: Dictionary) -> void:
	enemies.clear()
	for item in s.get("enemies", []):
		var e: Dictionary = item.duplicate(true)
		var p: Array = e.get("pos",[662.5,457.5])
		e.pos = Vector2(float(p[0]),float(p[1]))
		if e.has("artillery_target"):
			var aim: Array = e.artillery_target
			e.artillery_target = Vector2(float(aim[0]),float(aim[1]))
		var pooled: Dictionary=pool.acquire()
		pooled.merge(e,true)
		enemies.append(pooled)
	next_id = int(s.get("next_id",1))
	spawn_credit = float(s.get("spawn_credit",0.0))
	elapsed = float(s.get("elapsed",0.0))
	barrier = float(s.get("barrier",30.0))
	escaped_count = int(s.get("escaped_count",0))
	killed_count = int(s.get("killed_count",0))
	last_boss_minute = int(s.get("last_boss_minute",0))
	pending_boss = float(s.get("pending_boss",-1.0))
	pending_boss_minute = int(s.get("pending_boss_minute",0))
	hazard_serial = int(s.get("hazard_serial",1))
	hostile_projectiles.clear()
	for row in s.get("hostile_projectiles",[]):
		var item: Dictionary = row.duplicate(true)
		for key in ["pos","vel","target"]:
			var v: Array = item[key]
			item[key] = Vector2(float(v[0]),float(v[1]))
		hostile_projectiles.append(item)

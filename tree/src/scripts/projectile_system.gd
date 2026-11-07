extends RefCounted

# Single lifetime/swept-hit central loop for every player projectile.
# The owner supplies spatial hash, pool, damage and AoE event hooks.
static func advance(system, delta: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var removed: Array[int] = []
	for j in system.projectiles.size():
		var p: Dictionary = system.projectiles[j]
		var family: String = str(p.family)
		p.age = float(p.age) + delta
		if family == "mortar":
			p.pos = Vector2(p.start).lerp(Vector2(p.impact),clampf(float(p.age)/float(p.ttl),0.0,1.0))
			if float(p.age) >= float(p.ttl):
				system._explode(Vector2(p.impact),float(p.radius),float(p.damage),"mortar",str(p.id),field,tree,rng)
				removed.append(j)
			continue
		var old: Vector2 = p.pos
		if family == "rocket":
			var target: Dictionary = field.by_id(int(p.target))
			if target.is_empty():
				target = system._closest_enemy(Vector2(p.pos), field, 250.0)
				p.target = int(target.get("uid",-1))
			if not target.is_empty():
				p.velocity = Vector2(p.velocity).lerp((Vector2(target.pos)-Vector2(p.pos)).normalized()*250.0,clampf(delta*3.5,0.0,1.0))
		p.pos = old + Vector2(p.velocity) * delta
		for enemy in system.spatial.query_segment(old,Vector2(p.pos),45.0):
			if str(enemy.state) != "alive":
				continue
			var target_id: int = int(enemy.uid)
			if p.hits.has(str(target_id)):
				continue
			var hit: bool = RHitGeometry.segment_distance(Vector2(enemy.pos),old,Vector2(p.pos)) < float(enemy.size)*0.5 + float(p.radius)*0.4
			if not hit:
				continue
			p.hits[str(target_id)] = true
			var dtype := "cold" if family == "frost" else ("fire" if family == "rocket" else "kinetic")
			system._direct_hit(field,target_id,float(p.damage),dtype,str(p.id),tree,rng)
			if family == "frost":
				var victim: Dictionary = field.by_id(target_id)
				var burning: bool = not victim.is_empty() and not victim.burn.is_empty()
				field.slow_enemy(target_id,system.milestones.frost_slow(tree,burning) if system.milestones != null else 0.45,1.4)
				if tree.has_milestone("F",4):
					field.freeze_enemy(target_id,0.35)
			if family == "rocket":
				system._explode(Vector2(p.pos),float(p.get("aoe_radius",65.0)),float(p.damage)*0.65,"rocket",str(p.id)+":aoe",field,tree,rng)
				removed.append(j)
				break
			if int(p.pierce) <= 0:
				removed.append(j)
				break
			p.pierce = int(p.pierce) - 1
		if float(p.age) > float(p.ttl):
			removed.append(j)
	var unique_removed: Dictionary = {}
	for idx in removed:
		unique_removed[idx] = true
	var indices: Array = unique_removed.keys()
	indices.sort()
	indices.reverse()
	for idx in indices:
		if int(idx) < system.projectiles.size():
			system.pool.recycle(system.projectiles[int(idx)])
			system.projectiles.remove_at(int(idx))


class_name RSaveSchema
extends RefCounted

const SCHEMA_VERSION: int=1
const REQUIRED: Array[String]=["seed","tick","rng","economy","tree","train","field","weapons","speed","assisted"]

static func valid(container: Dictionary) -> bool:
	if int(container.get("schema_version",-1))!=SCHEMA_VERSION:
		return false
	var data: Variant=container.get("run",null)
	if not (data is Dictionary):
		return false
	var run: Dictionary=data
	if str(run.get("status",""))!="RUN":
		return false
	for field_name in REQUIRED:
		if not run.has(field_name):
			return false
	if int(run.tick)<0 or int(run.tick)>0x7FFFFFFFFFFFFFFE:
		return false
	if int(run.speed)<1 or int(run.speed)>3:
		return false
	for obj_key in ["rng","economy","tree","train","field","weapons"]:
		if not (run[obj_key] is Dictionary):
			return false
	var money: Dictionary=run.economy
	for key in ["tp","xp","scrap"]:
		var value: float=float(money.get(key,-1))
		if not is_finite(value) or value<0.0:
			return false
	var train: Dictionary=run.train
	if not RFloatSafety.valid_snapshot_numbers(train):
		return false
	if not (train.get("cars",null) is Array) or not (train.get("storage",null) is Array):
		return false
	if train.cars.size()<1 or train.cars.size()>RBalance.MAX_TRAIN or train.storage.size()>999:
		return false
	if not (train.cars[0] is Dictionary):
		return false
	for car in train.cars:
		if not (car is Dictionary) or not car.has("id") or not car.has("hp"):
			return false
		if not is_finite(float(car.hp)) or float(car.hp)<0.0:
			return false
	if str(train.cars[0].get("id",""))!="LOCOMOTIVE" or float(train.get("hull_hp",0))<=0.0:
		return false
	var field: Dictionary=run.field
	if not (field.get("enemies",null) is Array):
		return false
	if field.enemies.size()>RBalance.MAX_ENEMIES_PC:
		return false
	for enemy in field.enemies:
		if not (enemy is Dictionary) or not enemy.has("uid") or not enemy.has("pos"):
			return false
		if not (enemy.pos is Array) or enemy.pos.size()!=2:
			return false
		if not is_finite(float(enemy.pos[0])) or not is_finite(float(enemy.pos[1])):
			return false
	if not (field.get("hostile_projectiles",[]) is Array) or field.get("hostile_projectiles",[]).size()>256:
		return false
	var barrier: float=float(field.get("barrier",-1.0))
	if not is_finite(barrier) or barrier<=0.0 or barrier>RBalance.BARRIER_MAX:
		return false
	var attacks: Dictionary=run.weapons
	if not (attacks.get("projectiles",null) is Array) or attacks.projectiles.size()>RBalance.MAX_PROJECTILES_PC:
		return false
	if not run.rng.has("gameplay_state") or not run.rng.has("visual_state"):
		return false
	var purchased: Variant=run.tree.get("purchased",null)
	if not (purchased is Dictionary) or not purchased.has("C000"):
		return false
	return true

static func version_error(container: Dictionary) -> String:
	return "저장 스키마 버전이 지원되지 않습니다." if int(container.get("schema_version",-1))!=SCHEMA_VERSION else "저장 데이터 내용이 손상되었거나 죽은 런입니다."

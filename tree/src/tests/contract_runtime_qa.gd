extends SceneTree
## RAIL//SURVIVOR: deterministic Godot model/runtime contract regression suite.
## Writes input, expected, actual, PASS/FAIL to a JSONL evidence file.
## This does NOT simulate GUI button clicks or substitute for visual/performance QA.

const DEFAULT_CYCLES: int = 1
var cases: Array[Dictionary] = []
var passed: int = 0
var failed: int = 0
var repeats: int = DEFAULT_CYCLES
var output_path: String = "user://rail_contract_qa.jsonl"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--repeat="):
			repeats = clampi(int(arg.get_slice("=", 1)), 1, 100)
		elif arg.begins_with("--evidence="):
			output_path = arg.substr("--evidence=".length())
	call_deferred("_run")

func check(round_id: int, case_id: String, conditions: String, expected: Variant, actual: Variant, ok: bool) -> void:
	var record: Dictionary = {
		"round":round_id, "case":case_id,
		"input":conditions, "expected":str(expected), "actual":str(actual),
		"status":"PASS" if ok else "FAIL"
	}
	cases.append(record)
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("RAIL_QA_FAIL " + JSON.stringify(record))

func _run() -> void:
	var data := RData.new()
	var good_data: bool = data.load_all()
	check(0, "DATA_IMPORT", "load_all() JSON import", "true", good_data, good_data)
	if good_data:
		for cycle in range(1, repeats + 1):
			one_cycle(cycle, data)
	flush_evidence()

func one_cycle(cycle: int, data: RData) -> void:
	var counts: String = "%d/%d/%d" % [data.ordered_nodes.size(),data.ordered_wagons.size(),data.ordered_enemies.size()]
	check(cycle,"CONTENT_COUNTS","registry loads tree/wagons/enemies","121/36/14",counts,counts=="121/36/14")
	var wagon_catalog_ok: bool = true
	for spec in data.ordered_wagons:
		var built: Dictionary = RWagonFactory.build_from_spec(spec)
		wagon_catalog_ok = wagon_catalog_ok and str(built.get("id",""))==str(spec.id) and str(built.get("family",""))==str(spec.family) and float(built.get("hp",0))>0.0 and str(built.get("shape",""))=="rectangle"
	check(cycle,"WAGON_36_CONSTRUCTION","instantiate all 36 data definitions","36 valid rectangles",wagon_catalog_ok,wagon_catalog_ok)
	var ai_catalog_ok: bool = true
	for spec in data.ordered_enemies:
		var instance: Dictionary = REnemyFactory.create(spec,1,0.0,RBalance.CENTER,0)
		ai_catalog_ok = ai_catalog_ok and str(instance.get("kind",""))==str(spec.id) and str(instance.get("ai",""))==str(spec.ai) and bool(instance.get("can_escape",false))
	check(cycle,"ENEMY_14_CONSTRUCTION","construct 14 enemy families with their own AI tags","14 correct family IDs/AI",ai_catalog_ok,ai_catalog_ok)
	var flow := RStateMachine.new()
	var flow_ok: bool = true
	for scene_state in ["TITLE","MENU","RUN","PAUSE","RUN","DEFEAT","RESULT","MENU"]:
		flow_ok = flow.transition(scene_state) and flow_ok
	check(cycle,"SCREEN_STATE_FLOW","BOOT->TITLE->MENU->RUN->PAUSE->RUN->DEFEAT->RESULT->MENU","all transitions accepted",flow_ok,flow_ok)
	var tp_control := REconomy.new()
	tp_control.step(1.0,0)
	check(cycle,"TP_PER_SECOND","economy step 1 sec, no E research",0.0335,tp_control.tp,is_equal_approx(tp_control.tp,0.0335))
	var corner_ok: bool = true
	var marks: Array[float] = [0.0,1175.0,1950.0,3125.0]
	for i in 4:
		corner_ok = corner_ok and RRailPath.point(marks[i]).distance_to(RBalance.CORNERS[i]) < 0.001
	corner_ok = corner_ok and RRailPath.point(-28.0).distance_to(RRailPath.point(3872.0)) < 0.001
	check(cycle,"RAIL_GEOMETRY","four rectangular corners and negative track offset","true",corner_ok,corner_ok)
	var economy := REconomy.new()
	var tree := RTreeRules.new()
	tree.configure(data,economy)
	var train := RTrain.new()
	train.initialize()
	var initial: bool = train.cars.size()==1 and is_zero_approx(economy.tp) and is_equal_approx(economy.xp,20.0) and is_zero_approx(economy.scrap) and is_equal_approx(train.hull_hp,250.0)
	check(cycle,"NEW_RUN_STATE","new train/economy, no bonus","1 car/TP0/XP20/scrap0/HP250",str(initial),initial)
	var rejected: bool = not tree.purchase("W02",cycle)
	check(cycle,"PREREQUISITES","attempt W02 before W01","rejected",rejected,rejected)
	economy.tp = 10000.0
	economy.xp = 100000.0
	var tp_start: float = economy.tp
	var xp_start: float = economy.xp
	var bought: bool = tree.purchase("W01",cycle)
	var cancelled: bool = tree.cancel_same_tick("W01",cycle)
	var refunded: bool = bought and cancelled and tree.capacity()==1 and not tree.purchased.has("W01") and is_equal_approx(economy.tp,tp_start) and is_equal_approx(economy.xp,xp_start)
	check(cycle,"SAME_TICK_REFUND","buy W01 and cancel on same tick","wallet restored and W01 absent",str(refunded),refunded)
	var duplicate_refund: bool = tree.cancel_same_tick("W01",cycle)
	check(cycle,"NO_DOUBLE_REFUND","cancel W01 again","false",duplicate_refund,not duplicate_refund)
	var bought_all: bool = true
	for depth in range(1,11):
		if not tree.purchase("W%02d" % depth,cycle):
			bought_all = false
		if depth == 4:
			var high_tier_refund: bool = tree.cancel_same_tick("W04",cycle)
			check(cycle,"REJECT_TIER_4_REFUND","buy W04 and try same-tick refund before W05","false",high_tier_refund,not high_tier_refund and tree.purchased.has("W04"))
	var cap: int = tree.capacity()
	check(cycle,"W10_CAPACITY","purchase W01-W10, W10 gives +4","50",cap,bought_all and cap==50)
	economy.scrap = 100000.0
	var car_buys: bool = true
	for k in 49:
		if not train.add_car(data.ordered_wagons[k % 36],tree,economy,cycle):
			car_buys = false
			break
	var all_on_track: bool = true
	for slot in train.cars.size():
		var point: Vector2 = train.position_for(slot)
		if point.distance_to(RRailPath.nearest_rail_position(point)) > 0.01:
			all_on_track = false
			break
	check(cycle,"50_CARS","purchase 49 cars after W10 unlock, validate all positions","50 active/on rail",str(train.cars.size())+" active, on rail "+str(all_on_track),car_buys and train.cars.size()==50 and all_on_track)
	var storage_buy: bool = train.add_car(data.ordered_wagons[0],tree,economy,cycle)
	check(cycle,"EXTRA_CAR_STORAGE","purchase additional car with filled train","50+1 storage",str(train.cars.size())+"+"+str(train.storage.size()),storage_buy and train.cars.size()==50 and train.storage.size()==1)

	var rng := RGameRng.new()
	rng.start(cycle)
	var field := REnemyField.new()
	field.initialize(data)
	var spawned: bool = field.spawn(data.ordered_enemies[0],rng,0,RBalance.CENTER)
	check(cycle,"ENEMY_CREATE","spawn EN01 at center targeting corner 0","one enemy",field.enemies.size(),spawned and field.enemies.size()==1)
	var four_corners_escape: bool = true
	for corner_index in 4:
		var corner_field := REnemyField.new()
		corner_field.initialize(data)
		var corner_train := RTrain.new()
		corner_train.initialize()
		var placed: bool = corner_field.spawn(data.ordered_enemies[0],rng,corner_index,RBalance.CORNERS[corner_index])
		if placed:
			corner_field.step(1.0/60.0,corner_train,tree,rng)
		four_corners_escape = four_corners_escape and placed and corner_field.escaped_count==1 and is_equal_approx(corner_field.barrier,RBalance.BARRIER_MAX-1.0)
	check(cycle,"ESCAPE_ALL_4_CORNERS","spawn EN01 directly at each of 4 target corners and advance one tick","each escape reduces barrier by 1",four_corners_escape,four_corners_escape)
	if spawned and field.enemies.size()==1:
		var uid: int = int(field.enemies[0].uid)
		var hit: float = field.apply_damage(uid,1000000.0,"kinetic","qa:%d" % cycle,false)
		var again: float = field.apply_damage(uid,1000000.0,"kinetic","qa:%d" % cycle,false)
		check(cycle,"DAMAGE_DEDUP","kill enemy with hitID then hit same ID again","one kill, 0 duplicate",str(field.killed_count)+" kills / "+str(again)+" duplicate",hit>0.0 and is_zero_approx(again) and field.killed_count==1)

	var success: bool = economy.award_kill("qa:kill:%d" % cycle,1.0,0,false,0.0)
	var xp_after: float = economy.xp
	var scrap_after: float = economy.scrap
	var repeat: bool = economy.award_kill("qa:kill:%d" % cycle,1.0,0,false,0.0)
	check(cycle,"KILL_REWARD_ONCE","award same kill ID twice","first succeeds, duplicate rejected, unchanged wallet",str(success)+"/"+str(repeat)+"/"+str(economy.xp)+"/"+str(economy.scrap),
		success and not repeat and is_equal_approx(economy.xp,xp_after) and is_equal_approx(economy.scrap,scrap_after))
	field.initialize(data)
	var guns := RWeaponSystem.new()
	guns.initialize()
	var saved: Dictionary = {"status":"RUN","seed":cycle,"tick":60*cycle,"speed":1,"assisted":false,
		"rng":rng.capture(),"economy":economy.snapshot(),"tree":tree.snapshot(),"train":train.snapshot(),
		"field":field.snapshot(),"weapons":guns.snapshot()}
	var valid: bool = RSaveSchema.valid({"schema_version":1,"run":saved})
	check(cycle,"SAVE_SCHEMA","snapshot 50-car run, verify schema","true",valid,valid)
	var bad: Dictionary = saved.duplicate(true)
	bad.field.barrier = 0.0
	var rejected_save: bool = not RSaveSchema.valid({"schema_version":1,"run":bad})
	check(cycle,"REJECT_DEFEATED_SAVE","barrier=0 snapshot","rejected",rejected_save,rejected_save)
	var clock := RGameClock.new()
	clock.set_speed(3)
	var accelerated: int = RFixedTickRunner.tick_count(clock,60.0)
	clock.set_paused(true)
	var paused_ticks: int = RFixedTickRunner.tick_count(clock,60.0)
	check(cycle,"PAUSE_SPEED","speed 3, then pause","3 and 0 ticks",str(accelerated)+" and "+str(paused_ticks),
		accelerated==3 and paused_ticks==0 and clock.assisted)
	var defeats: Dictionary = {"count":0}
	train.defeated.connect(func() -> void: defeats.count = int(defeats.count)+1)
	train.take_hull_damage(250.0,tree)
	check(cycle,"HULL_DEFEAT","locomotive HP250, hit250 without armor node","HP0 and defeat event once",str(train.hull_hp)+"/"+str(defeats.count),
		is_zero_approx(train.hull_hp) and int(defeats.count)==1)
	var reset_once_ok: bool = tree.reset_once(cycle)
	train.synchronize_capacity(tree)
	var second_reset: bool = tree.reset_once(cycle)
	check(cycle,"TREE_RESET_ONCE","W01-W10 paid then reset once, synchronize 50-car roster","capacity 1/50 stored, no second reset",str(tree.capacity())+"/"+str(train.storage.size())+"/"+str(second_reset),
		reset_once_ok and tree.capacity()==1 and train.cars.size()==1 and train.storage.size()==50 and not second_reset)

func flush_evidence() -> void:
	var f := FileAccess.open(output_path,FileAccess.WRITE)
	if f==null:
		printerr("RAIL_QA_FAIL: cannot write evidence "+output_path)
		failed+=1
	else:
		for row in cases:
			f.store_line(JSON.stringify(row))
		f.flush()
		f.close()
	print("RAIL_QA_SUMMARY repeats=%d cases=%d pass=%d fail=%d evidence=%s" % [repeats,cases.size(),passed,failed,output_path])
	quit(0 if failed==0 else 1)

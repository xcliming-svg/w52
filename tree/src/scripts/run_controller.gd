class_name RRun
extends Control

signal finished(result: Dictionary)
signal back_to_menu
signal restart_requested
signal settings_requested

const PAUSE_SCENE := preload("res://scenes/pause_menu.tscn")

@onready var tree_panel: RTreePanel = $TreePanel
@onready var battlefield: RBattlefield = $Battlefield
@onready var physics_bridge: RPhysicsBridge = $Battlefield/PhysicsBridge
@onready var toolbar: HBoxContainer = $ToolbarScroll/Toolbar
@onready var toolbar_scroll: ScrollContainer = $ToolbarScroll
@onready var splitter: RLayoutSplitter = $Splitter

var registry: RData
var rng := RGameRng.new()
var clock := RGameClock.new()
var events := REventBus.new()
var economy := REconomy.new()
var tree := RTreeRules.new()
var milestones := RMilestones.new()
var progression := RProgressionDirector.new()
var autosave := RAutosave.new()
var train := RTrain.new()
var field := REnemyField.new()
var weapons := RWeaponSystem.new()
var visuals := RVfxManager.new()
var audio: RAudioRouter
var tick: int = 0
var speed: int = 1
var paused: bool = false
var assisted: bool = false
var status: String = "RUN"
var highest_train: int = 1
var seed_value: int = 1
var split_ratio: float = 0.31
var resume_data: Dictionary = {}
var options: Dictionary = {}
var hud_label: Label
var node_detail: Label
var wagon_list: OptionButton
var slot_list: OptionButton
var aim_list: OptionButton
var node_search: LineEdit
var buy_node_button: Button
var pause_button: Button
var rate_button: Button
var tutorial_label: Label
var warning_label: Label
var pause_overlay: Control

func _exit_tree() -> void:
	RCleanupLifecycle.clear_run(self)

func configure(data: RData, saved: Dictionary = {}) -> void:
	registry = data
	resume_data = saved.duplicate(true)

func _ready() -> void:
	if registry == null:
		registry = RData.new()
		if not registry.load_all():
			push_error(registry.error)
			return
	seed_value = int(Time.get_ticks_usec() & 0x7FFFFFFF)
	rng.start(seed_value)
	train.initialize()
	field.initialize(registry)
	tree.configure(registry,economy)
	train.milestones = milestones
	field.milestones = milestones
	weapons.milestones = milestones
	weapons.initialize()
	options = RSaveStore.settings()
	visuals.configure(options)
	tree_panel.set_session(self)
	battlefield.set_session(self)
	tree_panel.node_selected.connect(_on_node_selected)
	tree_panel.buy_requested.connect(_buy_node)
	field.enemy_damaged.connect(_on_enemy_damaged)
	field.enemy_killed.connect(_on_enemy_killed)
	field.enemy_escaped.connect(_on_enemy_escaped)
	field.battlefield_loss.connect(_finish)
	field.enemy_warning.connect(_warning)
	train.defeated.connect(func() -> void: _finish("기관차 파괴"))
	train.wagon_broken.connect(_on_wagon_broken)
	train.cars_changed.connect(_refresh_info)
	weapons.blast.connect(_blast)
	splitter.ratio_changed.connect(_on_split_ratio)
	audio = RAudioRouter.new()
	add_child(audio)
	audio.set_options(options)
	weapons.weapon_fired.connect(audio.on_weapon)
	weapons.blast.connect(audio.on_blast)
	field.enemy_warning.connect(audio.on_warning)
	_layout()
	_build_toolbar()
	if not resume_data.is_empty():
		_restore(resume_data)
	_refresh_info()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and status == "RUN":
		set_pause(true)
		if RHiddenWebPause.should_suspend(what):
			_warning(RHiddenWebPause.warning(),RBalance.CENTER)

func _layout() -> void:
	if not is_node_ready():
		return
	var split: float = split_ratio
	tree_panel.position = Vector2(0,48)
	tree_panel.size = Vector2(size.x*split,size.y-48)
	battlefield.position = Vector2(size.x*split,48)
	battlefield.size = Vector2(size.x*(1.0-split),size.y-48)
	splitter.position = Vector2(size.x*split - 3.0,48)
	splitter.size = Vector2(6.0,size.y-48)
	toolbar_scroll.position = Vector2(0,0)
	toolbar_scroll.size = Vector2(size.x,48)
	toolbar.custom_minimum_size.y = 44

func _build_toolbar() -> void:
	for child in toolbar.get_children():
		child.queue_free()
	hud_label = Label.new()
	hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(hud_label)
	node_detail = Label.new()
	node_detail.text = "중앙 기관"
	node_detail.custom_minimum_size.x = 150
	toolbar.add_child(node_detail)
	node_search = LineEdit.new()
	node_search.placeholder_text = "노드 검색"
	node_search.custom_minimum_size.x=105
	node_search.text_changed.connect(func(value: String) -> void: tree_panel.set_search(value))
	toolbar.add_child(node_search)
	buy_node_button = Button.new()
	buy_node_button.text="연구"
	buy_node_button.pressed.connect(func() -> void: _buy_node(tree_panel.selected_id))
	toolbar.add_child(buy_node_button)
	var refund := Button.new()
	refund.text = "직전 연구 취소"
	refund.pressed.connect(func() -> void: _cancel_node(tree_panel.selected_id))
	toolbar.add_child(refund)
	var reset := Button.new()
	reset.text = "연구 전체 초기화(1회)"
	reset.pressed.connect(_reset_tree)
	toolbar.add_child(reset)
	wagon_list = OptionButton.new()
	wagon_list.custom_minimum_size.x = 150
	for i in registry.ordered_wagons.size():
		var item: Dictionary = registry.ordered_wagons[i]
		wagon_list.add_item(str(item.name),i)
	toolbar.add_child(wagon_list)
	var add_car := Button.new()
	add_car.text = "객차 구매"
	add_car.pressed.connect(_buy_wagon)
	toolbar.add_child(add_car)
	slot_list = OptionButton.new()
	slot_list.custom_minimum_size.x=120
	toolbar.add_child(slot_list)
	var repair := Button.new()
	repair.text="선택차 수리"
	repair.pressed.connect(_repair_selected)
	toolbar.add_child(repair)
	var up := Button.new()
	up.text="앞으로"
	up.pressed.connect(func() -> void: _move_selected(-1))
	toolbar.add_child(up)
	var down := Button.new()
	down.text="뒤로"
	down.pressed.connect(func() -> void: _move_selected(1))
	toolbar.add_child(down)
	aim_list = OptionButton.new()
	for mode in ["탈출임박","최근접","정예","최대 HP"]:
		aim_list.add_item(mode)
	aim_list.item_selected.connect(_change_target_mode)
	toolbar.add_child(aim_list)
	rate_button = Button.new()
	rate_button.text = "1×"
	rate_button.pressed.connect(_cycle_speed)
	toolbar.add_child(rate_button)
	pause_button = Button.new()
	pause_button.text = "일시정지"
	pause_button.pressed.connect(toggle_pause)
	toolbar.add_child(pause_button)
	var settings_button := Button.new()
	settings_button.text = "설정"
	settings_button.pressed.connect(func() -> void: set_pause(true); settings_requested.emit())
	toolbar.add_child(settings_button)
	var menu_button := Button.new()
	menu_button.text = "메뉴"
	menu_button.pressed.connect(func() -> void: set_pause(true); autosave.on_menu_or_hide(snapshot()); back_to_menu.emit())
	toolbar.add_child(menu_button)
	tutorial_label = Label.new()
	tutorial_label.text = RTutorial.instruction(0)
	tutorial_label.position = Vector2(14,56)
	tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tutorial_label)
	var skip_tutorial:=Button.new()
	skip_tutorial.text="튜토리얼 건너뛰기"
	skip_tutorial.position=Vector2(18,84)
	skip_tutorial.pressed.connect(_skip_tutorial)
	add_child(skip_tutorial)
	skip_tutorial.visible=not bool(options.get("tutorial_shown",false))
	warning_label = Label.new()
	warning_label.position = Vector2(size.x*0.32,68)
	warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warning_label)

func _physics_process(_delta: float) -> void:
	if paused or status != "RUN":
		return
	var allowed_speed: int=RFrameBudget.effective_speed(speed,Engine.get_frames_per_second())
	if allowed_speed<speed:
		speed=allowed_speed
		_warning(RFrameBudget.alert(3,allowed_speed),RBalance.CENTER)
	clock.set_speed(speed)
	clock.paused=paused
	for _pass in RFixedTickRunner.tick_count(clock,Engine.get_frames_per_second()):
		_simulate_tick()
		if status != "RUN":
			break
	_refresh_info()
	battlefield.queue_redraw()
	tree_panel.queue_redraw()

func _simulate_tick() -> void:
	var dt := 1.0 / float(RBalance.TICK_RATE)
	clock.advance_one()
	tick=clock.tick
	var econ_level: int = tree.depth("E")
	economy.step(dt,econ_level)
	milestones.tick(dt,tree,train,field)
	train.step(dt,tree)
	field.step(dt,train,tree,rng)
	physics_bridge.sync_bosses(field)
	if status != "RUN":
		return
	weapons.current_tick = tick
	weapons.step(dt,train,field,tree,rng)
	visuals.set_density(field.enemies.size())
	visuals.tick(dt)
	if tick%RAutosave.PERIOD_TICKS==0:
		autosave.when_due(snapshot())
	if tutorial_label != null and is_instance_valid(tutorial_label):
		tutorial_label.visible = RTutorial.visible_at(tick,options)
		tutorial_label.text = RTutorial.instruction(tick)
	highest_train = maxi(highest_train,train.active_count())

func _on_enemy_damaged(uid: int, amount: float, where: Vector2, kind: String, critical: bool) -> void:
	events.combat_hit.emit(uid,amount,kind,"hit:%d:%d" % [uid,tick])
	visuals.on_damage(uid,amount,where,kind,critical)

func _on_enemy_killed(uid: int, where: Vector2, reward: float, family: String) -> void:
	var salvage: float = 0.0
	if REconomicCaps.can_salvage(tree.depth("E"),rng):
		salvage = 1.0
	var special: Dictionary = milestones.on_enemy_kill(tree,reward)
	var elite_bonus: bool = bool(special.elite_bonus)
	if REnemyDeathReward.apply(economy,uid,family,reward,tree.depth("E"),elite_bonus,salvage,tree.has_milestone("E",4)):
		events.emit_once("kill",str(uid),uid)
		visuals.on_death(where,reward,Color(str(registry.enemies.get(family,{}).get("color","#ffffff"))))
		var corpse: Dictionary = field.recent_deaths.get(uid,{})
		RAiSplitter.on_death(field,corpse,registry,rng,where)
		if int(special.frag_count)>0:
			weapons.fragment_blast(where,int(special.frag_count),field,tree,rng)
		if float(special.burn_echo)>0.0 and bool(field.recent_deaths.get(uid,{}).get("burning",false)):
			weapons.burn_death_echo(where,float(special.burn_echo),int(special.burn_spread),field,tree,rng)

func _on_wagon_broken(index: int) -> void:
	# Car IDs survive slot moves; defer mutation until all current attacks finish.
	if index>0 and index<train.cars.size():
		call_deferred("_store_broken_car_id",int(train.cars[index].get("instance_id",-1)))

func _store_broken_car_id(instance_id: int) -> void:
	if status!="RUN":
		return
	for index in range(1,train.cars.size()):
		var car: Dictionary=train.cars[index]
		if int(car.get("instance_id",-1))!=instance_id:
			continue
		if RWagonInstance.operational(car):
			return
		train.cars.remove_at(index)
		RTrainStorage.store(train,car)
		train.synchronize_capacity(tree)
		return

func _on_enemy_escaped(_uid: int, _corner: int, _amount: float) -> void:
	_warning("방벽 침투",RBalance.CENTER)

func _blast(pos: Vector2, radius: float, family: String) -> void:
	visuals.on_blast(pos,radius,family)

func _warning(msg: String, _pos: Vector2) -> void:
	events.warning_raised.emit(msg)
	if warning_label != null:
		warning_label.text = msg

func _skip_tutorial() -> void:
	RTutorial.dismiss(options)
	RSettingsStore.apply(options)
	if tutorial_label!=null:
		tutorial_label.visible=false
	for child in get_children():
		if child is Button and child.text=="튜토리얼 건너뛰기":
			child.visible=false

func _refresh_info() -> void:
	if hud_label == null:
		return
	hud_label.text=RHud.summary(self)
	if node_detail != null and registry != null:
		var node: Dictionary = registry.nodes.get(tree_panel.selected_id,{})
		node_detail.text = str(node.get("name",""))
	if buy_node_button != null:
		buy_node_button.disabled=not RTreePurchaseUI.button_enabled(tree,tree_panel.selected_id,paused)
	if rate_button != null:
		rate_button.text = "%d×" % speed
	if pause_button != null:
		pause_button.text = "계속" if paused else "일시정지"
	_refresh_car_slots()

func _refresh_car_slots() -> void:
	if slot_list==null:
		return
	var prev: int=slot_list.get_selected_id()
	var total: int=train.cars.size()+train.storage.size()
	var labels_unchanged: bool=slot_list.item_count==total
	if labels_unchanged:
		for i in train.cars.size():
			if slot_list.get_item_text(i)!="%d:%s" % [i,str(train.cars[i].get("family","기관"))]:
				labels_unchanged=false
				break
	if labels_unchanged:
		for s in train.storage.size():
			if slot_list.get_item_text(train.cars.size()+s)!="보관:%s" % str(train.storage[s].get("family","?")):
				labels_unchanged=false
				break
	if labels_unchanged:
		return
	slot_list.clear()
	for i in train.cars.size():
		slot_list.add_item("%d:%s" % [i,str(train.cars[i].get("family","기관"))],i)
	for s in train.storage.size():
		slot_list.add_item("보관:%s" % str(train.storage[s].get("family","?")),train.cars.size()+s)
	if slot_list.item_count>0:
		slot_list.select(clampi(prev,0,slot_list.item_count-1))

func _repair_selected() -> void:
	var index: int=slot_list.get_selected_id()
	if index<0:
		return
	if index<train.cars.size():
		train.repair(index,economy)
	else:
		train.repair_storage(index-train.cars.size(),economy,tree)
	_refresh_info()

func _move_selected(direction: int) -> void:
	var index: int=slot_list.get_selected_id()
	if train.swap_order(index,index+direction):
		_refresh_info()

func _change_target_mode(index: int) -> void:
	var slot: int=slot_list.get_selected_id()
	if slot>=0 and slot<train.cars.size():
		RWagonInstance.target_mode(train.cars[slot],["escape","nearest","elite","hp"][clampi(index,0,3)])
	_refresh_info()

func _on_split_ratio(value: float) -> void:
	split_ratio = clampf(value,0.25,0.45)
	_layout()

func _on_node_selected(_id: String) -> void:
	_refresh_info()

func _buy_node(id: String) -> void:
	if audio != null:
		audio.allow_from_user_input()
	if paused or status != "RUN":
		return
	if tree.purchase(id,tick):
		progression.record(tick,"research",id,economy.tp,economy.xp,economy.scrap)
		events.emit_once("economy","research:%s:%d" % [id,tick],"research")
		train.synchronize_capacity(tree)
		_refresh_info()

func _cancel_node(id: String) -> void:
	if tree.cancel_same_tick(id,tick):
		train.synchronize_capacity(tree)
		_refresh_info()

func _reset_tree() -> void:
	if paused or status != "RUN":
		return
	if tree.reset_once(tick):
		train.synchronize_capacity(tree)
		_refresh_info()

func _buy_wagon() -> void:
	if audio != null:
		audio.allow_from_user_input()
	if paused or status != "RUN":
		return
	var index: int = wagon_list.get_selected_id()
	if index < 0 or index >= registry.ordered_wagons.size():
		return
	var spent: float = economy.car_price()
	if train.add_car(registry.ordered_wagons[index],tree,economy,tick):
		progression.record(tick,"wagon",str(registry.ordered_wagons[index].id),economy.tp,economy.xp,economy.scrap)
		events.emit_once("economy","wagon:%d" % tick,"wagon")
		economy.scrap += milestones.on_scrap_spent(tree,spent)
	_refresh_info()

func _cycle_speed() -> void:
	speed = speed % 3 + 1
	if speed>1:
		assisted = true
	_refresh_info()

func set_pause(value: bool) -> void:
	paused = value
	clock.set_paused(value)
	if value:
		assisted = true
		autosave.on_menu_or_hide(snapshot())
		if pause_overlay == null or not is_instance_valid(pause_overlay):
			pause_overlay = PAUSE_SCENE.instantiate() as Control
			pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(pause_overlay)
			var continue_button: Button = pause_overlay.get_node("Center/Box/Continue") as Button
			var restart_button: Button = pause_overlay.get_node("Center/Box/Restart") as Button
			var settings_button: Button = pause_overlay.get_node("Center/Box/Settings") as Button
			var menu_button: Button = pause_overlay.get_node("Center/Box/Menu") as Button
			continue_button.pressed.connect(func() -> void: set_pause(false))
			restart_button.pressed.connect(func() -> void: restart_requested.emit())
			settings_button.pressed.connect(func() -> void: settings_requested.emit())
			menu_button.pressed.connect(func() -> void: back_to_menu.emit())
	elif pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
		pause_overlay = null
	_refresh_info()

func toggle_pause() -> void:
	set_pause(not paused)

func _input(event: InputEvent) -> void:
	if audio!=null and (event is InputEventMouseButton or event is InputEventKey):
		if event is InputEventMouseButton and event.pressed:
			audio.allow_from_user_input()
		elif event is InputEventKey and event.pressed:
			audio.allow_from_user_input()

func _unhandled_input(event: InputEvent) -> void:
	match RKeyBindings.action_for(event):
		"pause":toggle_pause();get_viewport().set_input_as_handled()
		"speed_up":speed=mini(3,speed+1);assisted=assisted or speed>1;get_viewport().set_input_as_handled()
		"speed_down":speed=maxi(1,speed-1);get_viewport().set_input_as_handled()
		"research":_buy_node(tree_panel.selected_id);get_viewport().set_input_as_handled()
		"tree_focus":tree_panel.focus_on(tree_panel.selected_id);get_viewport().set_input_as_handled()

func _finish(reason: String) -> void:
	if not RDeathRules.should_finish(status,reason):
		return
	status = "DEFEAT"
	paused = true
	RSaveStore.clear_resume()
	var record: Dictionary = snapshot()
	record.end_reason = reason
	record.kills = field.killed_count
	record.nodes = tree.purchased.size() - 1
	record.highest_train = highest_train
	RRecords.submit(record)
	finished.emit(record)

func snapshot() -> Dictionary:
	return {"status":"RUN" if status=="RUN" else status,"clock":clock.snapshot(),"event_bus":events.snapshot(),"seed":seed_value,"tick":tick,"speed":speed,"assisted":assisted,"paused":paused,"rng":rng.capture(),"economy":economy.snapshot(),"tree":tree.snapshot(),"train":train.snapshot(),"field":field.snapshot(),"weapons":weapons.snapshot(),"milestones":milestones.snapshot(),"progression":progression.snapshot(),"highest_train":highest_train}

func _restore(s: Dictionary) -> void:
	if not RResumeRun.apply(self,s):
		push_error(RRecoveryUi.recovery_message())
		return
	if paused:
		set_pause(true)

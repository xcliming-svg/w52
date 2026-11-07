class_name RApp
extends Control

const RUN_SCENE := preload("res://scenes/run.tscn")
const BOOT_SCENE := preload("res://scenes/boot.tscn")
const TITLE_SCENE := preload("res://scenes/title.tscn")
const MENU_SCENE := preload("res://scenes/main_menu.tscn")
const SETTINGS_SCENE := preload("res://scenes/settings.tscn")
const RESULT_SCENE := preload("res://scenes/result.tscn")
const RECORDS_SCENE := preload("res://scenes/records.tscn")
const ERROR_SCENE := preload("res://scenes/error.tscn")
const CODEX_SCENE := preload("res://scenes/codex.tscn")
var registry := RData.new()
var state_machine := RStateMachine.new()
var active_run: RRun
var current_screen: String = "BOOT"
var dialog: Control
var settings_data: Dictionary = {}
var root_box: VBoxContainer

func _ready() -> void:
	settings_data = RSettingsStore.get_current()
	RUiScaling.apply(self,float(settings_data.get("ui_scale",1.0)))
	current_screen = "BOOT"
	add_child(BOOT_SCENE.instantiate())
	if registry.load_all():
		_show_title()
	else:
		_show_error("콘텐츠 등록 오류: " + registry.error)

func _clear() -> void:
	if active_run != null and is_instance_valid(active_run):
		# Do not clear battle arrays synchronously from a kill/defeat signal.
		# RRun._exit_tree() owns cleanup after the current physics callback unwinds.
		active_run.queue_free()
	active_run = null
	if dialog != null and is_instance_valid(dialog):
		dialog.queue_free()
	dialog = null
	for n in get_children():
		if not n.is_queued_for_deletion():
			n.queue_free()

func _transition(target: String) -> void:
	if not state_machine.transition(target):
		push_error("잘못된 화면 전이: %s → %s" % [state_machine.current,target])
		return
	current_screen=target

func _screen(title: String) -> VBoxContainer:
	_clear()
	var bg := ColorRect.new()
	bg.color = Color("#091222")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(570,400)
	center.add_child(panel)
	var scene: PackedScene = _screen_template()
	root_box = scene.instantiate() as VBoxContainer
	panel.add_child(root_box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",36)
	root_box.add_child(heading)
	return root_box

func _screen_template() -> PackedScene:
	match current_screen:
		"TITLE": return TITLE_SCENE
		"MENU": return MENU_SCENE
		"SETTINGS": return SETTINGS_SCENE
		"RESULT": return RESULT_SCENE
		"RECORDS": return RECORDS_SCENE
		"CODEX": return CODEX_SCENE
		_: return ERROR_SCENE

func _button(parent: Node, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size.y = 45
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _show_title() -> void:
	_transition("TITLE")
	_screen("RAIL//SURVIVOR")
	var caption := Label.new()
	caption.text = "사각 레일 · 열차 생존 로그라이크"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(caption)
	_button(root_box,"시작",Callable(self,"_show_menu"))
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_inside_tree() and current_screen == "TITLE":
			_show_menu()
	)

func _show_menu() -> void:
	_transition("MENU")
	_screen("RAIL//SURVIVOR")
	_button(root_box,"새 게임",Callable(self,"_start_new"))
	_button(root_box,"이어하기",Callable(self,"_resume")).disabled = not RSaveStore.has_resume()
	_button(root_box,"설정",Callable(self,"_show_settings"))
	_button(root_box,"기록",Callable(self,"_show_records"))
	_button(root_box,"도감",Callable(self,"_show_codex"))
	_button(root_box,"튜토리얼 다시 표시",Callable(self,"_reset_tutorial"))
	_button(root_box,"종료",Callable(self,"_exit_application"))
	var hint := Label.new()
	hint.text = RBuildVersion.identity()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(hint)
	var balance_note:=Label.new()
	balance_note.text=RBalanceProvenance.tooltip()
	root_box.add_child(balance_note)
	if RPlatformService.is_web():
		var warning := Label.new()
		warning.text = RPlatformOptionGuard.platform_note()+"\n"+RFontRegistry.missing_reason()
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root_box.add_child(warning)

func _start_new() -> void:
	if not RTreeData.valid(registry):
		_show_error("필수 콘텐츠를 검증하지 못했습니다.")
		return
	RSaveStore.clear_resume()
	_open_run({})

func _resume() -> void:
	var save: Dictionary = RSaveStore.load_run()
	if save.is_empty():
		_show_error("저장 데이터가 유효하지 않습니다. 백업도 확인했으므로 새 게임을 시작하십시오.")
		return
	_open_run(save)

func _open_run(saved: Dictionary) -> void:
	_clear()
	_transition("RUN")
	active_run = RUN_SCENE.instantiate() as RRun
	active_run.configure(registry,saved)
	active_run.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_run.finished.connect(_show_result)
	active_run.back_to_menu.connect(_show_menu)
	active_run.restart_requested.connect(_start_new)
	active_run.settings_requested.connect(_show_settings)
	add_child(active_run)

func _show_result(details: Dictionary) -> void:
	_transition("DEFEAT")
	_transition("RESULT")
	_screen("게임 종료 — " + str(details.get("end_reason","패배")))
	var game_time: int = int(details.get("tick",0)) / 60
	var info := Label.new()
	info.text = "생존: %d시간 %d분 %d초\n처치: %d  |  최대 객차: %d량\n연구: %d  |  시드: %s\n기록 분류: %s" % [int(game_time/3600),int(game_time/60)%60,game_time%60,int(details.get("kills",0)),int(details.get("highest_train",1)),int(details.get("nodes",0)),str(details.get("seed",0)),"보조 이용" if bool(details.get("assisted",false)) else "일반"]
	root_box.add_child(info)
	_button(root_box,"재시작",Callable(self,"_start_new"))
	_button(root_box,"메뉴",Callable(self,"_show_menu"))

func _show_records() -> void:
	_transition("RECORDS")
	_screen("게임 기록")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 290
	root_box.add_child(scroll)
	var list := VBoxContainer.new()
	scroll.add_child(list)
	var groups: Dictionary=RAssistedRunRecords.separate(RRecords.ordered_by_survival())
	for item in groups.ordinary+groups.assisted:
		var label := Label.new()
		label.text = "%s | %.1f분 | %d킬 | %s" % [str(item.get("version","?")),float(item.get("time_seconds",0))/60.0,int(item.get("kills",0)),"보조" if bool(item.get("assisted",false)) else "일반"]
		list.add_child(label)
	_button(root_box,"메뉴",Callable(self,"_show_menu"))

func _show_codex() -> void:
	_transition("CODEX")
	_screen("객차 · 적 · 트리 도감")
	var line:=Label.new()
	var totals: Dictionary=RHelpCodex.counts(registry)
	line.text="객차 %d종 / 적 %d종 / 노드 %d개" % [int(totals.wagons),int(totals.enemies),int(totals.nodes)]
	root_box.add_child(line)
	var tabs:=TabContainer.new()
	tabs.custom_minimum_size.y=300.0
	root_box.add_child(tabs)
	for category in ["wagon","enemy","tree"]:
		var box:=ScrollContainer.new()
		box.name={"wagon":"객차","enemy":"적","tree":"기술"}[category]
		tabs.add_child(box)
		var list:=VBoxContainer.new()
		box.add_child(list)
		for entry in RHelpCodex.content(registry,category):
			var item:=Label.new()
			item.text=str(entry.id)+" · "+str(entry.name)+" — "+str(entry.description)
			item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			list.add_child(item)
	_button(root_box,"메뉴",Callable(self,"_show_menu"))

func _reset_tutorial() -> void:
	settings_data.tutorial_shown=false
	_save_options()
	_show_menu()

func _show_error(message: String) -> void:
	_transition("ERROR")
	_screen(RErrorScreen.heading())
	var label := Label.new()
	label.text = RErrorScreen.with_recovery(message)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(label)
	_button(root_box,"메뉴로 돌아가기",Callable(self,"_show_menu"))

func _show_settings() -> void:
	if current_screen == "RUN" and active_run != null:
		active_run.set_pause(true)
		active_run.visible = false
	_transition("SETTINGS")
	if active_run == null or not is_instance_valid(active_run):
		_screen("게임 설정")
	else:
		var layer := ColorRect.new()
		layer.color = Color(0.02,0.04,0.08,0.97)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(layer)
		dialog = layer
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(center)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(520,480)
		center.add_child(panel)
		root_box = SETTINGS_SCENE.instantiate() as VBoxContainer
		panel.add_child(root_box)
		var title := Label.new()
		title.text = "설정"
		root_box.add_child(title)
	for setting in ["master","music","sfx","vfx","number_scale","ui_scale"]:
		var line := HBoxContainer.new()
		root_box.add_child(line)
		var label := Label.new()
		label.text = {"master":"전체음량","music":"음악","sfx":"효과음","vfx":"효과밀도","number_scale":"피해숫자 크기","ui_scale":"UI 배율"}[setting]
		label.custom_minimum_size.x = 155
		line.add_child(label)
		var slider := HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0.8 if setting=="ui_scale" else (0.7 if setting=="number_scale" else 0.0)
		slider.max_value = 1.5 if setting=="ui_scale" else (1.5 if setting=="number_scale" else 1.0)
		slider.step = 0.05
		slider.value = float(settings_data.get(setting,1))
		slider.value_changed.connect(_on_slider_value.bind(setting))
		line.add_child(slider)
	for toggle_key in ["low_flash","shake","high_contrast"]:
		var check := CheckButton.new()
		check.text = {"low_flash":"저섬광","shake":"화면 흔들림","high_contrast":"고대비"}[toggle_key]
		check.button_pressed = bool(settings_data.get(toggle_key,false))
		check.toggled.connect(_on_toggle_value.bind(toggle_key))
		root_box.add_child(check)
	var cb := OptionButton.new()
	for text in ["일반","적록 색각","청황 색각","전체 색각 보정"]:
		cb.add_item(text)
	cb.select(clampi(int(settings_data.get("color_mode",0)),0,3))
	cb.item_selected.connect(func(index: int) -> void: settings_data.color_mode=index; _save_options())
	root_box.add_child(cb)
	_button(root_box,"뒤로",Callable(self,"_close_settings"))

func _on_slider_value(value: float, key: String) -> void:
	settings_data[key] = value
	_save_options()

func _on_toggle_value(value: bool, key: String) -> void:
	settings_data[key] = value
	_save_options()

func _save_options() -> void:
	RSettingsStore.apply(settings_data)
	RUiScaling.apply(self,float(settings_data.get("ui_scale",1.0)))
	if active_run != null and is_instance_valid(active_run):
		active_run.options = settings_data.duplicate(true)
		active_run.visuals.configure(settings_data)
		if active_run.audio != null:
			active_run.audio.set_options(settings_data)

func _close_settings() -> void:
	if active_run != null and is_instance_valid(active_run):
		if dialog != null and is_instance_valid(dialog):
			dialog.queue_free()
		dialog = null
		active_run.visible = true
		_transition("RUN")
	else:
		_show_menu()

func _exit_application() -> void:
	var result: String=RQuitHandler.request(self,get_tree())
	if RPlatformService.is_web():
		var note := Label.new()
		note.text=result
		root_box.add_child(note)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and current_screen=="TITLE":
		_show_menu()
		get_viewport().set_input_as_handled()

extends Control
## W52 16:9 fixed-ratio battle/build UI. Prototype combat/economy values are illustrative,
## NOT approved gameplay balance or the final battle simulation.
signal defeated

const UI = preload("res://scripts/ui_style.gd")
const FONT: Font = preload("res://assets/fonts/ui_ko_subset.woff2")
const MAX_WEEK := 52
const DEMO_BATTLE_COST := 40
const DEMO_WEEK_REWARD := 70
const DIALOGUE_COUNT := 5
const TREE_RECT := Rect2(0, 84, 1376, 892)
const TREE_CENTER_LOCAL := Vector2(688, 446)
const DRAG_THRESHOLD := 8.0
const POPUP_SIZE := Vector2(390, 274)
const POPUP_BUTTON_OFFSET := Vector2(205, 194)
const DIALOGUE_RECT := Rect2(28, 778, 1320, 171)
const NODES := [
    {"id":"hq", "name":"본부", "kind":"root", "parent":"", "p":Vector2(920, 825), "week":1, "requires":[], "symbol":"HQ", "detail":"기술트리의 뿌리"},
    {"id":"robot_factory", "name":"로봇 공장", "kind":"production", "parent":"hq", "p":Vector2(350, 630), "week":1, "requires":[], "symbol":"R", "detail":"로봇 5종의 생산시설"},
    {"id":"walker_factory", "name":"워커 공장", "kind":"production", "parent":"hq", "p":Vector2(1050, 630), "week":9, "requires":[], "symbol":"W", "detail":"워커 4종의 생산시설"},
    {"id":"radar", "name":"레이더 기지", "kind":"tech", "parent":"hq", "p":Vector2(1730, 630), "week":15, "requires":[], "symbol":"T", "detail":"드론 관제·장거리 정밀 조준"},
    {"id":"reactor", "name":"동력로", "kind":"tech", "parent":"hq", "p":Vector2(2190, 630), "week":32, "requires":[], "symbol":"P", "detail":"중전차·폭격기 고출력 동력"},
    {"id":"armory", "name":"무기고", "kind":"tech", "parent":"robot_factory", "p":Vector2(490, 405), "week":10, "requires":[], "symbol":"A", "detail":"로켓·포격·공격기 무장 기술"},
    {"id":"machine_shop", "name":"기계 공작소", "kind":"tech", "parent":"walker_factory", "p":Vector2(1150, 405), "week":18, "requires":[], "symbol":"M", "detail":"고급 차체·워커 플랫폼"},
    {"id":"drone_hangar", "name":"드론 격납고", "kind":"production", "parent":"radar", "p":Vector2(1820, 405), "week":15, "requires":[], "symbol":"D", "detail":"드론 3종의 생산시설"},
    {"id":"rifle", "name":"소총병", "kind":"unit", "parent":"robot_factory", "p":Vector2(70, 165), "week":1, "requires":["robot_factory"], "symbol":"1", "detail":"저비용 범용 사격·기본 대공 보조"},
    {"id":"mg", "name":"기관총병", "kind":"unit", "parent":"robot_factory", "p":Vector2(270, 165), "week":2, "requires":["robot_factory"], "symbol":"2", "detail":"연사와 경량 표적 처리"},
    {"id":"mortar", "name":"박격포", "kind":"unit", "parent":"robot_factory", "p":Vector2(470, 165), "week":4, "requires":["robot_factory"], "symbol":"3", "detail":"저비용 간접포격"},
    {"id":"anti_tank", "name":"대전차병", "kind":"unit", "parent":"robot_factory", "p":Vector2(670, 165), "week":10, "requires":["robot_factory","armory"], "symbol":"4", "detail":"저비용 대장갑 특화"},
    {"id":"artillery", "name":"야포", "kind":"unit", "parent":"robot_factory", "p":Vector2(870, 165), "week":21, "requires":["robot_factory","armory","radar"], "symbol":"5", "detail":"장거리 후열 화력"},
    {"id":"car", "name":"장갑차", "kind":"unit", "parent":"walker_factory", "p":Vector2(990, 165), "week":9, "requires":["walker_factory"], "symbol":"6", "detail":"경량 워커 전열·빠른 연사"},
    {"id":"tank", "name":"전차", "kind":"unit", "parent":"walker_factory", "p":Vector2(1180, 165), "week":18, "requires":["walker_factory","machine_shop"], "symbol":"7", "detail":"범용 장갑 전열"},
    {"id":"destroyer", "name":"구축전차", "kind":"unit", "parent":"walker_factory", "p":Vector2(1370, 165), "week":29, "requires":["walker_factory","machine_shop","radar"], "symbol":"8", "detail":"단일 대전차 플랫폼"},
    {"id":"heavy", "name":"중전차", "kind":"unit", "parent":"walker_factory", "p":Vector2(1560, 165), "week":36, "requires":["walker_factory","machine_shop","reactor"], "symbol":"9", "detail":"고내구 전열"},
    {"id":"fighter", "name":"전투기", "kind":"unit", "parent":"drone_hangar", "p":Vector2(1760, 165), "week":15, "requires":["drone_hangar"], "symbol":"F", "detail":"공중 요격"},
    {"id":"attacker", "name":"공격기", "kind":"unit", "parent":"drone_hangar", "p":Vector2(1960, 165), "week":24, "requires":["drone_hangar","armory"], "symbol":"G", "detail":"지상 지원·범위 공격"},
    {"id":"bomber", "name":"폭격기", "kind":"unit", "parent":"drone_hangar", "p":Vector2(2160, 165), "week":40, "requires":["drone_hangar","reactor"], "symbol":"B", "detail":"대규모 폭격"}
]

const UPGRADES := {
    "rifle": [["고속 장전","연사 개선"],["대공 추적","공중 대응 개선"]],
    "mg": [["연사 강화","지속 화력"],["표적 전환","경량 다수 대응"]],
    "mortar": [["확산 포탄","광역 지원"],["자동 장전","발사 속도"]],
    "anti_tank": [["관통탄","장갑 피해"],["유도 조준","표적 추적"]],
    "artillery": [["장포신","사거리"],["고폭 포탄","포격 범위"]],
    "car": [["추가 장갑","생존력"],["속사 포탑","경량 표적 대응"]],
    "tank": [["복합 장갑","생존력"],["고폭탄","소형 광역"]],
    "destroyer": [["관통 포탄","대장갑 화력"],["정밀 조준","표적 추적"]],
    "heavy": [["강화 장갑","생존력"],["중포탄","일격 피해"]],
    "fighter": [["요격 레이더","공중 탐지"],["속사 기관포","연사"]],
    "attacker": [["확산 로켓","광역"],["정밀 유도탄","장갑 대응"]],
    "bomber": [["확산 폭탄","타격 범위"],["중량 폭탄","일격 피해"]]
}

var week: int = 1
var g: int = 160
var phase: String = "dialogue" # dialogue, prepare, battle, result
var dialogue_index: int = 0
var help_index: int = 1
var selected_id: String = ""
var hover_id: String = ""
var placements: Array[String] = []
var owned_buildings: Array[String] = ["hq", "robot_factory"]
var full_tree_view: bool = false
var log_items: Array[String] = []
var speed: int = 1
var battle_seconds: float = 0.0
var camera_offset: Vector2 = Vector2.ZERO
var camera_target: Vector2 = Vector2.ZERO
var pan_armed: bool = false
var pan_dragging: bool = false
var pan_start_mouse: Vector2 = Vector2.ZERO
var pan_start_camera: Vector2 = Vector2.ZERO
var pan_press_node_id: String = ""

var full_view_button: Button
var deploy_button: Button
var battle_button: Button
var prev_button: Button
var next_button: Button
var speed_one: Button
var speed_two: Button
var log_scroll: ScrollContainer
var log_column: VBoxContainer
var tree_surface: Control
var tree_canvas: Control
var popup_surface: Control
var dialogue_surface: Control


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    _create_controls()
    _set_week_intro()
    _refresh_all()


func restore_state(data: Dictionary) -> void:
    week = clampi(int(data.get("week", 1)), 1, MAX_WEEK)
    g = maxi(0, int(data.get("g", 160)))
    var requested: String = str(data.get("phase", "dialogue"))
    phase = requested if requested in ["dialogue", "prepare", "battle", "result"] else "dialogue"
    if phase == "battle":
        phase = "prepare"
    dialogue_index = clampi(int(data.get("dialogue", 0)), 0, DIALOGUE_COUNT)
    help_index = clampi(int(data.get("help", week)), 1, week)
    owned_buildings = ["hq", "robot_factory"]
    var stored: Variant = data.get("buildings", [])
    if stored is Array:
        # Reconstruct only valid building paths, regardless of serialized order.
        for pass_index in range(stored.size()):
            for item in stored:
                var node := _find_node(str(item))
                if node.is_empty() or str(node["kind"]) == "unit" or str(item) in owned_buildings:
                    continue
                if int(node["week"]) <= week and _has_building(str(node["parent"])):
                    owned_buildings.append(str(item))
    placements.clear()
    var saved_placements: Variant = data.get("placements", [])
    if saved_placements is Array:
        for item in saved_placements:
            var node := _find_node(str(item))
            if not node.is_empty() and str(node["kind"]) == "unit" and _is_node_unlocked(node) and placements.size() < 12:
                placements.append(str(item))
    if phase == "dialogue" and dialogue_index >= DIALOGUE_COUNT:
        phase = "prepare"
    selected_id = ""
    full_tree_view = false
    camera_offset = _clamp_pan(TREE_CENTER_LOCAL - _find_node("hq")["p"])
    camera_target = camera_offset
    log_items = ["%d주차 전투 준비 중입니다." % week]
    for id in placements:
        log_items.append("%s 배치됨" % str(_find_node(id)["name"]))
    _refresh_all()


func snapshot() -> Dictionary:
    return {"week":week, "g":g, "phase":phase, "dialogue":dialogue_index,
        "help":help_index, "placements":placements.duplicate(),
        "buildings":owned_buildings.duplicate()}

func _create_controls() -> void:
    # Only the tree surface is clipped. Panels and interactive Controls remain
    # separate layers so a dragged line can never enter the battlefield.
    tree_surface = Control.new()
    tree_surface.name = "TreeClip"
    tree_surface.position = TREE_RECT.position
    tree_surface.size = TREE_RECT.size
    tree_surface.clip_contents = true
    tree_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(tree_surface)

    # Draw on a child: the clipping parent masks the entire canvas,
    # including lines partially outside its rectangle.
    tree_canvas = Control.new()
    tree_canvas.name = "TreeArt"
    tree_canvas.size = TREE_RECT.size
    tree_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tree_canvas.draw.connect(_draw_tree)
    tree_surface.add_child(tree_canvas)

    popup_surface = Control.new()
    popup_surface.name = "NodeInfoLayer"
    popup_surface.size = Vector2(1920, 1080)
    popup_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    popup_surface.draw.connect(_draw_popup)
    add_child(popup_surface)

    dialogue_surface = Control.new()
    dialogue_surface.name = "DialogueLayer"
    dialogue_surface.size = Vector2(1920, 1080)
    dialogue_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dialogue_surface.draw.connect(_draw_dialogue_overlay)
    add_child(dialogue_surface)

    full_view_button = UI.make_button("전체 기술도", Vector2(188, 52))
    full_view_button.position = Vector2(22, 100)
    full_view_button.size = Vector2(188, 52)
    full_view_button.add_theme_font_size_override("font_size", 22)
    full_view_button.pressed.connect(_toggle_tree_view)
    add_child(full_view_button)

    deploy_button = UI.make_button("배치", Vector2(160, 62))
    deploy_button.position = Vector2(-500, -500)
    deploy_button.size = Vector2(160, 62)
    deploy_button.add_theme_font_size_override("font_size", 26)
    deploy_button.pressed.connect(_action_selected)
    add_child(deploy_button)

    prev_button = UI.make_button("〈", Vector2(72, 64))
    next_button = UI.make_button("〉", Vector2(72, 64))
    for b in [prev_button, next_button]:
        b.size = Vector2(72, 64)
        b.add_theme_font_size_override("font_size", 32)
        add_child(b)
    prev_button.position = Vector2(26, 995)
    next_button.position = Vector2(1278, 995)
    prev_button.pressed.connect(func() -> void: _change_help(-1))
    next_button.pressed.connect(func() -> void: _change_help(1))

    speed_one = UI.make_button("1×", Vector2(103, 52))
    speed_two = UI.make_button("2×", Vector2(103, 52))
    for b in [speed_one, speed_two]:
        b.size = Vector2(103, 52)
        b.add_theme_font_size_override("font_size", 26)
        add_child(b)
    speed_one.position = Vector2(1688, 16)
    speed_two.position = Vector2(1791, 16)
    speed_one.toggle_mode = true
    speed_two.toggle_mode = true
    speed_one.pressed.connect(func() -> void: _set_speed(1))
    speed_two.pressed.connect(func() -> void: _set_speed(2))

    battle_button = UI.make_button("전투 시작", Vector2(505, 74))
    battle_button.position = Vector2(1395, 991)
    battle_button.size = Vector2(505, 74)
    battle_button.add_theme_font_size_override("font_size", 32)
    battle_button.add_theme_stylebox_override("normal", UI._button_style(UI.GOLD))
    battle_button.add_theme_stylebox_override("hover", UI._button_style(UI.GOLD.lightened(0.12)))
    battle_button.add_theme_color_override("font_color", UI.BACKGROUND)
    battle_button.add_theme_color_override("font_hover_color", UI.BACKGROUND)
    battle_button.pressed.connect(_battle_action)
    add_child(battle_button)

    log_scroll = ScrollContainer.new()
    log_scroll.position = Vector2(1396, 792)
    log_scroll.size = Vector2(502, 173)
    log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    log_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(log_scroll)
    log_column = VBoxContainer.new()
    log_column.add_theme_constant_override("separation", 12)
    log_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    log_scroll.add_child(log_column)


func _set_week_intro() -> void:
    phase = "dialogue"
    dialogue_index = 0
    help_index = week
    placements.clear()
    selected_id = ""
    hover_id = ""
    # At the beginning of each week keep the HQ identifiable above the dialogue overlay.
    camera_offset = _clamp_pan(TREE_CENTER_LOCAL - _find_node("hq")["p"])
    camera_target = camera_offset
    pan_armed = false
    pan_dragging = false
    battle_seconds = 0.0
    log_items = ["%d주차 전투 준비 중입니다." % week]


func _find_node(id: String) -> Dictionary:
    for item in NODES:
        if str(item["id"]) == id:
            return item
    return {}


func _has_building(id: String) -> bool:
    return id in owned_buildings


func _node_visible(node: Dictionary) -> bool:
    if full_tree_view or _has_building(str(node["id"])):
        return true
    return _has_building(str(node["parent"]))


func _is_node_unlocked(node: Dictionary) -> bool:
    if week < int(node["week"]):
        return false
    if str(node["kind"]) == "unit":
        for requirement in node["requires"]:
            if not _has_building(str(requirement)):
                return false
        return true
    return _has_building(str(node["parent"]))


func _node_half_size(node: Dictionary) -> float:
    match str(node["kind"]):
        "root":
            return 52.0
        "production":
            return 44.0
        "tech":
            return 40.0
        _:
            return 36.0


func _toggle_tree_view() -> void:
    full_tree_view = not full_tree_view
    full_view_button.text = "기본 트리" if full_tree_view else "전체 기술도"
    if not selected_id.is_empty() and not _node_visible(_find_node(selected_id)):
        selected_id = ""
    camera_offset = _clamp_pan(camera_offset)
    camera_target = camera_offset
    _refresh_all()


func _build_selected() -> void:
    var node := _find_node(selected_id)
    if node.is_empty() or str(node["kind"]) == "unit" or str(node["kind"]) == "root":
        return
    if phase not in ["dialogue", "prepare"] or not _node_visible(node) or not _is_node_unlocked(node):
        return
    var id := str(node["id"])
    if _has_building(id):
        return
    # No approved construction price: this is an instant, zero-cost UI demonstration.
    owned_buildings.append(id)
    _append_log("%s 즉시 건설 (비용 미정·시연)" % str(node["name"]))
    _refresh_all()

func _node_tree_local(node: Dictionary) -> Vector2:
    return node["p"] + camera_offset


func _node_screen(node: Dictionary) -> Vector2:
    return TREE_RECT.position + _node_tree_local(node)


func _selected_ancestors() -> Array[String]:
    var result: Array[String] = []
    var starts: Array[String] = [selected_id]
    var selected := _find_node(selected_id)
    if not selected.is_empty() and str(selected["kind"]) == "unit":
        for req in selected["requires"]:
            starts.append(str(req))
    for start in starts:
        var current: String = start
        while not current.is_empty():
            if current not in result:
                result.append(current)
            var node := _find_node(current)
            if node.is_empty():
                break
            current = str(node["parent"])
    return result


func _node_visual_rect(node: Dictionary) -> Rect2:
    # Entire shape and measured label, with the single 112% focus scale.
    var p: Vector2 = node["p"]
    var half: float = _node_half_size(node) * 1.12
    var label_width: float = FONT.get_string_size(str(node["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
    var left := minf(p.x - half, p.x - label_width * 0.5)
    var right := maxf(p.x + half, p.x + label_width * 0.5)
    var bottom := p.y + half + 7.0 + 22.0 + FONT.get_descent(22)
    return Rect2(Vector2(left, p.y - half), Vector2(right - left, bottom - (p.y - half)))

func _readable_tree_area() -> Rect2:
    # Avoid counting a node completely hidden by the dialogue overlay.
    var visible_height: float = TREE_RECT.size.y
    if phase == "dialogue":
        visible_height = DIALOGUE_RECT.position.y - TREE_RECT.position.y
    return Rect2(Vector2.ZERO, Vector2(TREE_RECT.size.x, visible_height))


func _clamp_pan(candidate: Vector2) -> Vector2:
    # Keep one complete node icon and name legible. Use the union of
    # per-node visibility regions instead of a whole-tree bounding box.
    var visible := _readable_tree_area()
    var nearest := candidate
    var nearest_distance := INF
    for node in NODES:
        if not _node_visible(node):
            continue
        var artwork := _node_visual_rect(node)
        # One-pixel numeric safety margin avoids Rect2.encloses() rejecting
        # a node due to float rounding when a pan ends exactly at the edge.
        var pan_margin := Vector2.ONE * 2.0
        var min_offset := visible.position + pan_margin - artwork.position
        var max_offset := visible.end - pan_margin - artwork.end
        var projected := candidate.clamp(min_offset, max_offset)
        var distance := candidate.distance_squared_to(projected)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = projected
    return nearest


func _select_node(id: String) -> void:
    var node := _find_node(id)
    if node.is_empty() or not _node_visible(node):
        return
    selected_id = id
    camera_target = _clamp_pan(TREE_CENTER_LOCAL - node["p"])
    _update_popup()
    _queue_ui_redraw()


func _popup_rect() -> Rect2:
    if selected_id.is_empty():
        return Rect2()
    var node := _find_node(selected_id)
    if node.is_empty():
        return Rect2()
    var p := _node_screen(node)
    var panel_x: float = clampf(p.x + 100.0, 28.0, TREE_RECT.size.x - POPUP_SIZE.x - 28.0)
    var bottom_limit: float = 480.0 if phase == "dialogue" else 670.0
    var panel_y: float = clampf(p.y - 112.0, 104.0, bottom_limit)
    return Rect2(Vector2(panel_x, panel_y), POPUP_SIZE)


func _upgrade_rect() -> Rect2:
    if selected_id.is_empty():
        return Rect2()
    var node := _find_node(selected_id)
    if node.is_empty() or str(node["kind"]) != "unit":
        return Rect2()
    var panel := _popup_rect()
    var x := panel.end.x + 12.0
    if x + 420.0 > TREE_RECT.size.x - 12.0:
        x = panel.position.x - 432.0
    return Rect2(Vector2(x, panel.position.y), Vector2(420, 256))


func _update_popup() -> void:
    if selected_id.is_empty():
        deploy_button.visible = false
        return
    var node := _find_node(selected_id)
    if node.is_empty():
        deploy_button.visible = false
        return
    var panel := _popup_rect()
    deploy_button.position = panel.position + POPUP_BUTTON_OFFSET
    var kind := str(node["kind"])
    deploy_button.visible = kind != "root" and (kind == "unit" or not _has_building(str(node["id"])))
    deploy_button.disabled = phase not in ["dialogue", "prepare"] or not _is_node_unlocked(node)
    if kind == "unit":
        deploy_button.text = "배치" if not deploy_button.disabled else "배치 불가"
    else:
        deploy_button.text = "시연 건설" if not deploy_button.disabled else "건설 불가"


func _action_selected() -> void:
    var node := _find_node(selected_id)
    if node.is_empty():
        return
    if str(node["kind"]) == "unit":
        _deploy_selected()
    else:
        _build_selected()

func _process(delta: float) -> void:
    if camera_offset.distance_squared_to(camera_target) > 0.5:
        camera_offset = _clamp_pan(camera_offset.lerp(camera_target, minf(1.0, delta * 9.0)))
        _update_popup()
        _queue_ui_redraw()
    if phase == "battle":
        var previous_second := int(battle_seconds)
        battle_seconds += delta * speed
        if int(battle_seconds) != previous_second and int(battle_seconds) in [3, 7, 11, 15]:
            _append_log("전선에서 교전이 진행 중입니다. (시연)")
        if battle_seconds >= 18.0:
            battle_seconds = 18.0
            phase = "result"
            g += DEMO_WEEK_REWARD
            _append_log("전투 종료 — 시연 결과 표시")
            _refresh_all()
        else:
            _queue_ui_redraw()


func _node_at(mouse: Vector2) -> String:
    if not TREE_RECT.has_point(mouse):
        return ""
    if phase == "dialogue" and DIALOGUE_RECT.has_point(mouse):
        return ""
    if not selected_id.is_empty():
        if _popup_rect().has_point(mouse) or _upgrade_rect().has_point(mouse):
            return ""
    if Rect2(Vector2(22, 100), Vector2(188, 52)).has_point(mouse):
        return ""
    for node in NODES:
        if not _node_visible(node):
            continue
        var half: float = _node_half_size(node) * 1.12
        var center := _node_screen(node)
        if Rect2(center - Vector2.ONE * half, Vector2.ONE * half * 2.0).has_point(mouse):
            return str(node["id"])
    return ""

func _start_pan(mouse: Vector2) -> void:
    pan_armed = true
    pan_dragging = false
    pan_start_mouse = mouse
    # Stop any existing smooth focus animation before anchoring the mouse.
    camera_target = camera_offset
    pan_start_camera = camera_offset
    pan_press_node_id = _node_at(mouse)


func _update_pan(mouse: Vector2) -> void:
    if not pan_armed:
        return
    var delta := mouse - pan_start_mouse
    if not pan_dragging and delta.length() < DRAG_THRESHOLD:
        return
    pan_dragging = true
    hover_id = ""
    camera_offset = _clamp_pan(pan_start_camera + delta)
    camera_target = camera_offset
    _update_popup()
    _queue_ui_redraw()


func _finish_pan(mouse: Vector2) -> void:
    if not pan_armed:
        return
    var was_dragging := pan_dragging
    var clicked_id := pan_press_node_id
    pan_armed = false
    pan_dragging = false
    pan_press_node_id = ""
    if was_dragging:
        # A drag release must never select a different node.
        camera_target = camera_offset
        return
    if not clicked_id.is_empty() and _node_at(mouse) == clicked_id:
        _select_node(clicked_id)


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and pan_armed:
        _update_pan((event as InputEventMouseMotion).position)
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseButton and pan_armed:
        var release := event as InputEventMouseButton
        if release.button_index == MOUSE_BUTTON_LEFT and not release.pressed:
            _finish_pan(release.position)
            get_viewport().set_input_as_handled()
            return
    if phase != "dialogue" or not (event is InputEventKey):
        return
    var key_event := event as InputEventKey
    if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
        _advance_dialogue()
        get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var mouse := (event as InputEventMouseMotion).position
        var found := _node_at(mouse)
        if found != hover_id:
            hover_id = found
            _queue_ui_redraw()
    elif event is InputEventMouseButton:
        var click := event as InputEventMouseButton
        if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
            return
        if phase == "dialogue" and DIALOGUE_RECT.has_point(click.position):
            _advance_dialogue()
            return
        if TREE_RECT.has_point(click.position):
            if not selected_id.is_empty() and (_popup_rect().has_point(click.position) or _upgrade_rect().has_point(click.position)):
                return
            if Rect2(Vector2(22, 100), Vector2(188, 52)).has_point(click.position):
                return
            _start_pan(click.position)
        elif Rect2(1376, 84, 544, 652).has_point(click.position):
            _click_ally(click.position)


func _advance_dialogue() -> void:
    if phase != "dialogue":
        return
    dialogue_index += 1
    if dialogue_index == 3:
        _select_node("rifle") # First unit on the integrated tree.
    elif dialogue_index >= DIALOGUE_COUNT:
        phase = "prepare"
    _refresh_all()


func _dialogue_content() -> Array[String]:
    if week == 1:
        return [
            "52주 동안 주마다 한 차례 전투를 준비합니다.",
            "왼쪽의 노드에서 사용할 전략을 살펴보세요.",
            "소총병 경로가 선택되었습니다.",
            "유닛 정보를 열고 배치 버튼을 사용하세요.",
            "물자 G와 배치를 확인한 뒤 전투를 시작하세요."
        ]
    return [
        "%d주차 작전 브리핑을 시작합니다." % week,
        "앞선 전투 기록을 바탕으로 빌드를 점검하세요.",
        "이번 주 사용할 유닛 노드를 확인하세요.",
        "전장 하단은 아군, 상단은 적군입니다.",
        "준비를 마치면 전투를 시작할 수 있습니다."
    ]


func _change_help(step: int) -> void:
    help_index = clampi(help_index + step, 1, week)
    _refresh_all()


func _set_speed(next_speed: int) -> void:
    speed = next_speed
    _refresh_all()


func _deploy_selected() -> void:
    if phase == "battle" or phase == "result":
        return
    var node := _find_node(selected_id)
    if node.is_empty() or str(node["kind"]) != "unit" or not _is_node_unlocked(node) or phase not in ["dialogue", "prepare"]:
        return
    if placements.size() >= 12:
        _append_log("현재 시연 배치 슬롯이 가득 찼습니다.")
        return
    placements.append(selected_id)
    _append_log("%s 1기 배치됨" % str(node["name"]))
    _refresh_all()


func _battle_action() -> void:
    if phase == "result" and week < MAX_WEEK:
        week += 1
        _set_week_intro()
        _refresh_all()
        return
    if phase != "prepare":
        return
    if placements.is_empty():
        _append_log("아군 유닛을 먼저 배치하세요.")
        return
    if g < DEMO_BATTLE_COST:
        _append_log("물자 G가 부족합니다. (시연 비용 %d G)" % DEMO_BATTLE_COST)
        return
    g -= DEMO_BATTLE_COST
    phase = "battle"
    battle_seconds = 0
    _append_log("전투가 시작되었습니다. (시연)")
    _refresh_all()


func _click_ally(mouse: Vector2) -> void:
    var size := _grid_size()
    var cols: int = size.x
    var rows: int = size.y
    var grid_pos := Vector2(1376 + (544 - cols * 46) * 0.5, 84 + (652 - rows * 46) * 0.5)
    var cell := ((mouse - grid_pos) / 46.0).floor()
    if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
        return
    if cell.y < rows / 2:
        return
    for i in range(placements.size()):
        var pos := Vector2i(1 + (i % (cols - 2)), rows - 1 - (i / (cols - 2)))
        if pos == Vector2i(cell):
            _select_node(placements[i])
            return


func _grid_size() -> Vector2i:
    if week <= 13:
        return Vector2i(6, 6)
    if week <= 26:
        return Vector2i(8, 8)
    if week <= 39:
        return Vector2i(10, 8)
    return Vector2i(10, 10)


func _append_log(message: String) -> void:
    log_items.append(message)
    if log_items.size() > 100:
        log_items.pop_front()
    _refresh_log()
    _queue_ui_redraw()


func _refresh_log() -> void:
    var stick_bottom := log_scroll.scroll_vertical >= log_scroll.get_v_scroll_bar().max_value - log_scroll.size.y - 20
    for child in log_column.get_children():
        log_column.remove_child(child)
        child.queue_free()
    for entry in log_items:
        var label := UI.make_label("◆  " + entry, 22, UI.TEXT)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.custom_minimum_size.x = 480
        log_column.add_child(label)
    if stick_bottom:
        call_deferred("_scroll_log_to_end")


func _scroll_log_to_end() -> void:
    if is_instance_valid(log_scroll):
        log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


func _refresh_all() -> void:
    full_view_button.text = "기본 트리" if full_tree_view else "전체 기술도"
    prev_button.disabled = help_index <= 1
    next_button.disabled = help_index >= week
    speed_one.button_pressed = speed == 1
    speed_two.button_pressed = speed == 2
    speed_one.add_theme_color_override("font_color", UI.BACKGROUND if speed == 1 else UI.TEXT)
    speed_one.add_theme_stylebox_override("normal", UI._button_style(UI.GOLD if speed == 1 else UI.PANEL))
    speed_one.add_theme_stylebox_override("pressed", UI._button_style(UI.GOLD if speed == 1 else UI.PANEL))
    speed_two.add_theme_color_override("font_color", UI.BACKGROUND if speed == 2 else UI.TEXT)
    speed_two.add_theme_stylebox_override("normal", UI._button_style(UI.GOLD if speed == 2 else UI.PANEL))
    speed_two.add_theme_stylebox_override("pressed", UI._button_style(UI.GOLD if speed == 2 else UI.PANEL))
    battle_button.disabled = phase == "battle" or (phase == "result" and week == MAX_WEEK)
    if phase == "battle":
        battle_button.text = "전투 진행 중"
    elif phase == "result" and week == MAX_WEEK:
        battle_button.text = "52주 완료"
    elif phase == "result":
        battle_button.text = "다음 주"
    else:
        battle_button.text = "전투 시작"
    _update_popup()
    _refresh_log()
    _queue_ui_redraw()


func _text(value: String, p: Vector2, font_size: int, color: Color = UI.TEXT) -> void:
    draw_string(FONT, p + Vector2(0, font_size), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _layer_text(surface: Control, value: String, p: Vector2, font_size: int, color: Color = UI.TEXT) -> void:
    surface.draw_string(FONT, p + Vector2(0, font_size), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _layer_box(surface: Control, rect: Rect2, fill: Color, border: Color = UI.BORDER) -> void:
    surface.draw_rect(rect, fill)
    surface.draw_rect(rect, border, false, 2.0)


func _queue_ui_redraw() -> void:
    queue_redraw()
    if is_instance_valid(tree_surface):
        tree_canvas.queue_redraw()
    if is_instance_valid(popup_surface):
        popup_surface.queue_redraw()
    if is_instance_valid(dialogue_surface):
        dialogue_surface.queue_redraw()


func _box(rect: Rect2, fill: Color, border: Color = UI.BORDER) -> void:
    draw_rect(rect, fill)
    draw_rect(rect, border, false, 2.0)


func _draw() -> void:
    # Fixed HUD background is drawn at the root; TreeArt renders in a clipped
    # child Control and can never paint into the battlefield or other panels.
    draw_rect(Rect2(0, 0, 1920, 1080), UI.BACKGROUND)
    _box(TREE_RECT, UI.GAME_BACKGROUND)
    for x in range(0, 1376, 56):
        draw_line(Vector2(x, 84), Vector2(x, 976), UI.GRID, 1.0)
    for y in range(84, 976, 56):
        draw_line(Vector2(0, y), Vector2(1376, y), UI.GRID, 1.0)
    _box(Rect2(0, 0, 1376, 84), UI.HEADER)
    _box(Rect2(1376, 0, 544, 84), UI.HEADER)
    _box(Rect2(0, 976, 1376, 104), UI.PANEL)
    _box(Rect2(1376, 84, 544, 652), UI.GAME_BACKGROUND)
    _box(Rect2(1376, 736, 544, 240), UI.PANEL)
    _box(Rect2(1376, 976, 544, 104), UI.PANEL)
    _text("%02d주차" % week, Vector2(44, 16), 38)
    draw_line(Vector2(233, 17), Vector2(233, 67), UI.BORDER, 2)
    _text("%s G" % _group_digits(g), Vector2(271, 17), 37, UI.GOLD)
    var secs := int(battle_seconds)
    _text("%02d:%02d" % [secs / 60, secs % 60], Vector2(1410, 16), 36)
    _draw_field()
    _text("전투 정보", Vector2(1400, 747), 28)
    draw_line(Vector2(1400, 790), Vector2(1896, 790), UI.BORDER, 2)
    _text("도움말", Vector2(115, 992), 23, UI.GOLD)
    _text(_help_text(), Vector2(240, 992), 25)


func _group_digits(value: int) -> String:
    var s := str(value)
    var output := ""
    while s.length() > 3:
        output = "," + s.substr(s.length() - 3) + output
        s = s.substr(0, s.length() - 3)
    return s + output


func _help_text() -> String:
    if help_index == 1:
        return "본부에서 위로 확장합니다. 전체 기술도로 20노드를 확인하세요."
    if help_index == 18:
        return "아군을 클릭하면 연결된 트리 노드로 포커스됩니다."
    if help_index == 35:
        return "전투 속도는 1× 또는 2×로 변경할 수 있습니다."
    if help_index == 52:
        return "지난 도움말은 왼쪽 화살표로 다시 볼 수 있습니다."
    return "%d주차: 빌드와 전장 배치를 점검하세요." % help_index


func _draw_tree() -> void:
    # Only the 20 structural nodes render here. The 24 upgrades are drawn
    # in the independent _draw_popup detail panel, never on the tree.
    var path := _selected_ancestors()
    for node in NODES:
        if not _node_visible(node):
            continue
        var parent_id := str(node["parent"])
        if parent_id.is_empty():
            continue
        var parent := _find_node(parent_id)
        if not _node_visible(parent):
            continue
        var a := _node_tree_local(parent)
        var b := _node_tree_local(node)
        var middle_y := (a.y + b.y) * 0.5
        var highlight := str(node["id"]) in path and parent_id in path
        var owned := _has_building(str(node["id"]))
        var tint: Color = UI.TEAL if highlight or owned else (UI.TREE_LINE if _is_node_unlocked(node) else UI.TREE_LINE.darkened(0.4))
        tree_canvas.draw_polyline(PackedVector2Array([
            a - Vector2(0, _node_half_size(parent)),
            Vector2(a.x, middle_y),
            Vector2(b.x, middle_y),
            b + Vector2(0, _node_half_size(node))]), tint, 5.0 if highlight else 3.5, true)
    for node in NODES:
        if not _node_visible(node):
            continue
        var p := _node_tree_local(node)
        if p.y < -120 or p.y > TREE_RECT.size.y + 120 or p.x < -120 or p.x > TREE_RECT.size.x + 120:
            continue
        var id := str(node["id"])
        var unlocked := _is_node_unlocked(node)
        var focused := id == selected_id
        var hovered := id == hover_id
        var half: float = _node_half_size(node) * (1.12 if focused or hovered else 1.0)
        var kind := str(node["kind"])
        var fill: Color = UI.NODE_FILL if unlocked or _has_building(id) else UI.LOCKED
        var border: Color = UI.GOLD if focused else (UI.TEAL if unlocked or _has_building(id) else UI.TREE_LINE)
        if kind == "root":
            var hex := PackedVector2Array([
                p + Vector2(-half, 0), p + Vector2(-half * 0.5, -half * 0.866),
                p + Vector2(half * 0.5, -half * 0.866), p + Vector2(half, 0),
                p + Vector2(half * 0.5, half * 0.866), p + Vector2(-half * 0.5, half * 0.866)])
            tree_canvas.draw_colored_polygon(hex, fill)
            hex.append(hex[0])
            tree_canvas.draw_polyline(hex, border, 4.0, true)
        elif kind == "production":
            var square := Rect2(p - Vector2.ONE * half, Vector2.ONE * half * 2.0)
            tree_canvas.draw_rect(square, fill)
            tree_canvas.draw_rect(square, border, false, 4.0)
        elif kind == "tech":
            var diamond := PackedVector2Array([
                p + Vector2(0, -half), p + Vector2(half, 0),
                p + Vector2(0, half), p + Vector2(-half, 0)])
            tree_canvas.draw_colored_polygon(diamond, fill)
            diamond.append(diamond[0])
            tree_canvas.draw_polyline(diamond, border, 4.0, true)
        else:
            tree_canvas.draw_circle(p, half, fill)
            tree_canvas.draw_arc(p, half, 0.0, TAU, 48, border, 4.0, true)
        var symbol: String = str(node["symbol"])
        var symbol_width: float = FONT.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
        _layer_text(tree_canvas, symbol, p + Vector2(-symbol_width * 0.5, -17), 26, border)
        var name: String = str(node["name"])
        var label_width: float = FONT.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
        _layer_text(tree_canvas, name, p + Vector2(-label_width * 0.5, half + 7.0), 22,
            UI.TEXT if unlocked or _has_building(id) else UI.MUTED)


func _draw_popup() -> void:
    if selected_id.is_empty():
        return
    var node := _find_node(selected_id)
    if node.is_empty():
        return
    var panel := _popup_rect()
    _layer_box(popup_surface, panel, UI.PANEL, UI.TEAL)
    _layer_text(popup_surface, str(node["name"]), panel.position + Vector2(24, 15), 30)
    var status := "보유" if _has_building(selected_id) else ("조건 충족" if _is_node_unlocked(node) else "잠금")
    if str(node["kind"]) == "unit":
        status = "배치 가능" if _is_node_unlocked(node) else "배치 잠금"
    _layer_text(popup_surface, "최소 W%02d · %s (후보)" % [int(node["week"]), status],
        panel.position + Vector2(24, 64), 20, UI.GOLD)
    if str(node["kind"]) == "unit":
        _layer_text(popup_surface, "필수 시설", panel.position + Vector2(24, 91), 18, UI.GOLD)
        for i in range(node["requires"].size()):
            var req_id: String = str(node["requires"][i])
            var required_node := _find_node(req_id)
            var mark := "보유" if _has_building(req_id) else "미보유"
            _layer_text(popup_surface, "• %s [%s]" % [str(required_node["name"]), mark],
                panel.position + Vector2(24, 118 + i * 23), 19, UI.TEXT if _has_building(req_id) else UI.MUTED)
        _draw_upgrade_panel()
    else:
        var parent := _find_node(str(node["parent"]))
        if not parent.is_empty():
            _layer_text(popup_surface, "선행: %s (%s)" % [
                str(parent["name"]), "보유" if _has_building(str(parent["id"])) else "미보유"],
                panel.position + Vector2(24, 101), 21, UI.MUTED)
        _layer_text(popup_surface, str(node["detail"]), panel.position + Vector2(24, 138), 21, UI.TEXT)
        if str(node["kind"]) != "root":
            _layer_text(popup_surface, "즉시 완공 · 건설 비용 미정(시연)",
                panel.position + Vector2(24, 173), 18, UI.GOLD)


func _draw_upgrade_panel() -> void:
    var content: Array = UPGRADES.get(selected_id, [])
    if content.size() != 2:
        return
    var panel := _upgrade_rect()
    _layer_box(popup_surface, panel, UI.PANEL, UI.GOLD)
    _layer_text(popup_surface, "고유 강화 · 조회 전용", panel.position + Vector2(18, 12), 24, UI.GOLD)
    _layer_text(popup_surface, str(_find_node(selected_id)["detail"]), panel.position + Vector2(20, 44), 18, UI.MUTED)
    for i in range(2):
        var pair: Array = content[i]
        var y: float = 70.0 + i * 72.0
        _layer_text(popup_surface, "%s  %s" % ["A" if i == 0 else "B", str(pair[0])],
            panel.position + Vector2(22, y), 23, UI.TEXT)
        _layer_text(popup_surface, str(pair[1]) + " (제안)",
            panel.position + Vector2(52, y + 30), 19, UI.MUTED)
    _layer_text(popup_surface, "비용·구매·전투 효과 미확정",
        panel.position + Vector2(20, 222), 18, UI.GOLD)

func _draw_field() -> void:
    var sz := _grid_size()
    var cols: int = sz.x
    var rows: int = sz.y
    var start := Vector2(1376 + (544 - cols * 46) * 0.5, 84 + (652 - rows * 46) * 0.5)
    for r in range(rows):
        for c in range(cols):
            var pos := start + Vector2(c * 46, r * 46)
            _box(Rect2(pos, Vector2(46, 46)), UI.ENEMY_CELL if r < rows / 2 else UI.ALLY_CELL, UI.GRID_BORDER)
    var mid_y: float = start.y + float(rows / 2) * 46.0
    draw_line(Vector2(start.x, mid_y), Vector2(start.x + cols * 46, mid_y), UI.TEXT, 2.0)
    for i in range(3):
        var enemy_p := start + Vector2((1 + i * 2) * 46 + 8, (0 if i < 2 else 1) * 46 + 8)
        draw_rect(Rect2(enemy_p, Vector2(30, 30)), UI.ENEMY)
        _text("×", enemy_p + Vector2(6, -4), 28)
    for i in range(placements.size()):
        var col: int = 1 + i % (cols - 2)
        var row: int = rows - 1 - int(i / (cols - 2))
        var ally_p := start + Vector2(col * 46 + 8, row * 46 + 8)
        draw_rect(Rect2(ally_p, Vector2(30, 30)), UI.TEAL)
        _text("■", ally_p + Vector2(3, -2), 25, UI.BACKGROUND)


func _draw_dialogue_overlay() -> void:
    if phase != "dialogue":
        return
    _layer_box(dialogue_surface, DIALOGUE_RECT, UI.DIALOGUE_PANEL, UI.GOLD)
    _layer_box(dialogue_surface, Rect2(52, 800, 112, 125), UI.NODE_FILL, UI.GOLD)
    var speaker := "해설" if dialogue_index == 0 or dialogue_index == 2 or dialogue_index == 4 else "작전 참모"
    _layer_text(dialogue_surface, "≡" if speaker == "해설" else "◆", Vector2(83, 815), 48, UI.GOLD)
    _layer_text(dialogue_surface, speaker, Vector2(196, 793), 26, UI.GOLD)
    var text_lines := _dialogue_content()
    _layer_text(dialogue_surface, text_lines[min(dialogue_index, DIALOGUE_COUNT - 1)], Vector2(196, 845), 28)
    _layer_text(dialogue_surface, "Space  다음 ›", Vector2(1137, 905), 21, UI.MUTED)

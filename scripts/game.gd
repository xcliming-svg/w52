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
const INFO_PANEL_RECT := Rect2(930, 170, 420, 560)
const FIELD_RECT := Rect2(1376, 84, 544, 652)
const GRID_CELL_SIZE := 46.0
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
var selected_id: String = "hq" # Last explicit tree selection (HQ fallback).
var selected_instance_id: String = ""
var user_selected_context: bool = false
var hover_id: String = ""
var placements: Array[Dictionary] = []
var next_instance_serial: int = 1
var placement_mode: String = "NORMAL" # NORMAL, PLACE_NEW
var pending_unit_type_id: String = ""
var field_drag_armed: bool = false
var field_dragging: bool = false
var field_drag_start: Vector2 = Vector2.ZERO
var field_drag_instance_id: String = ""
var field_hover_cell: Vector2i = Vector2i(-1, -1)
var field_drag_cell: Vector2i = Vector2i(-1, -1)
var show_related_links: bool = false
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
var info_title: Label
var info_status: Label
var info_reason: Label
var info_scroll: ScrollContainer
var info_column: VBoxContainer
var secondary_button: Button
var info_content_key: String = ""


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
    next_instance_serial = 1
    var saved_placements: Variant = data.get("placements", [])
    if saved_placements is Array:
        for item in saved_placements:
            if not (item is Dictionary):
                continue
            var entry: Dictionary = item
            var node := _find_node(str(entry.get("unit_id", "")))
            var cell := Vector2i(int(entry.get("col", -1)), int(entry.get("row", -1)))
            var instance_id := str(entry.get("instance_id", ""))
            if instance_id.is_empty() or node.is_empty() or str(node["kind"]) != "unit" or not _is_node_unlocked(node) or not _is_ally_cell(cell) or _instance_index(instance_id) >= 0 or _instance_at_cell(cell) >= 0 or placements.size() >= 12:
                continue
            placements.append({"instance_id":instance_id, "unit_id":str(node["id"]), "col":cell.x, "row":cell.y})
            var serial_part := instance_id.trim_prefix("unit_")
            if serial_part.is_valid_int():
                next_instance_serial = maxi(next_instance_serial, int(serial_part) + 1)
    if phase == "dialogue" and dialogue_index >= DIALOGUE_COUNT:
        phase = "prepare"
    selected_id = "hq"
    selected_instance_id = ""
    placement_mode = "NORMAL"
    pending_unit_type_id = ""
    field_drag_armed = false
    field_dragging = false
    field_drag_instance_id = ""
    field_drag_cell = Vector2i(-1, -1)
    field_hover_cell = Vector2i(-1, -1)
    pan_armed = false
    pan_dragging = false
    user_selected_context = false
    info_content_key = ""
    full_tree_view = false
    camera_offset = _clamp_pan(TREE_CENTER_LOCAL - _find_node("hq")["p"])
    camera_target = camera_offset
    log_items = ["%d주차 전투 준비 중입니다." % week]
    for entry in placements:
        log_items.append("%s 배치됨" % str(_find_node(str(entry["unit_id"]))["name"]))
    _refresh_all()


func snapshot() -> Dictionary:
    return {"week":week, "g":g, "phase":phase, "dialogue":dialogue_index,
        "help":help_index, "placements":placements.duplicate(true),
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
    popup_surface.position = INFO_PANEL_RECT.position
    popup_surface.size = INFO_PANEL_RECT.size
    popup_surface.mouse_filter = Control.MOUSE_FILTER_STOP
    popup_surface.draw.connect(_draw_info_frame)
    add_child(popup_surface)

    info_title = UI.make_label("", 30)
    info_title.position = Vector2(18, 12)
    info_title.size = Vector2(382, 43)
    info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    info_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    popup_surface.add_child(info_title)
    info_status = UI.make_label("", 19, UI.GOLD)
    info_status.position = Vector2(18, 57)
    info_status.size = Vector2(382, 29)
    info_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    info_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    popup_surface.add_child(info_status)
    info_scroll = ScrollContainer.new()
    info_scroll.position = Vector2(18, 98)
    info_scroll.size = Vector2(382, 350)
    info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    info_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    popup_surface.add_child(info_scroll)
    info_column = VBoxContainer.new()
    info_column.add_theme_constant_override("separation", 9)
    info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_scroll.add_child(info_column)
    info_reason = UI.make_label("", 17, UI.MUTED)
    info_reason.position = Vector2(18, 453)
    info_reason.size = Vector2(382, 27)
    info_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    info_reason.mouse_filter = Control.MOUSE_FILTER_IGNORE
    popup_surface.add_child(info_reason)

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

    deploy_button = UI.make_button("배치", Vector2(184, 62))
    deploy_button.position = Vector2(18, 483)
    deploy_button.size = Vector2(184, 62)
    deploy_button.add_theme_font_size_override("font_size", 23)
    deploy_button.pressed.connect(_on_info_primary_action)
    popup_surface.add_child(deploy_button)
    secondary_button = UI.make_button("관련 정보", Vector2(184, 62))
    secondary_button.position = Vector2(218, 483)
    secondary_button.size = Vector2(184, 62)
    secondary_button.add_theme_font_size_override("font_size", 20)
    secondary_button.pressed.connect(_on_info_secondary_action)
    popup_surface.add_child(secondary_button)

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
    next_instance_serial = 1
    selected_id = "hq"
    selected_instance_id = ""
    placement_mode = "NORMAL"
    pending_unit_type_id = ""
    field_drag_armed = false
    field_dragging = false
    field_hover_cell = Vector2i(-1, -1)
    user_selected_context = false
    info_content_key = ""
    show_related_links = false
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
    if not _node_visible(_find_node(selected_id)):
        selected_id = "hq"
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
    var active_id := _active_tree_node_id()
    var starts: Array[String] = [active_id]
    var selected := _find_node(active_id)
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
    return Rect2(Vector2.ZERO, Vector2(INFO_PANEL_RECT.position.x - 12.0, visible_height))


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


func _select_node(id: String, user_input: bool = true) -> void:
    var node := _find_node(id)
    if node.is_empty() or not _node_visible(node):
        return
    selected_id = id
    selected_instance_id = ""
    placement_mode = "NORMAL"
    pending_unit_type_id = ""
    show_related_links = false
    field_drag_armed = false
    if user_input:
        user_selected_context = true
    camera_target = _clamp_pan(TREE_CENTER_LOCAL - node["p"])
    _refresh_info_panel()
    _queue_ui_redraw()


func _info_panel_rect() -> Rect2:
    return INFO_PANEL_RECT


func _draw_info_frame() -> void:
    _layer_box(popup_surface, Rect2(Vector2.ZERO, INFO_PANEL_RECT.size), UI.PANEL, UI.TEAL)
    popup_surface.draw_line(Vector2(18, 93), Vector2(402, 93), UI.BORDER, 2.0)
    popup_surface.draw_line(Vector2(18, 479), Vector2(402, 479), UI.BORDER, 2.0)


func _selected_instance() -> Dictionary:
    var index := _instance_index(selected_instance_id)
    return placements[index] if index >= 0 else {}


func _active_tree_node_id() -> String:
    var entry := _selected_instance()
    if not entry.is_empty():
        return str(entry["unit_id"])
    return selected_id if not _find_node(selected_id).is_empty() else "hq"


func _resolve_info_context() -> Dictionary:
    var entry := _selected_instance()
    if not entry.is_empty():
        return {"kind":"FIELD_INSTANCE", "id":str(entry["unit_id"]), "entry":entry}
    var node := _find_node(selected_id)
    if node.is_empty():
        selected_id = "hq"
        node = _find_node("hq")
    return {"kind":"TREE_UNIT" if str(node["kind"]) == "unit" else "TREE_BUILDING",
        "id":str(node["id"])}


func _missing_requirement(node: Dictionary) -> String:
    if str(node["kind"]) != "unit":
        var parent_id := str(node["parent"])
        return parent_id if not parent_id.is_empty() and not _has_building(parent_id) else ""
    for req in node["requires"]:
        if not _has_building(str(req)):
            return str(req)
    return ""


func _get_info_actions(context: Dictionary) -> Dictionary:
    var actions := {"primary":"", "enabled":false, "reason":"", "secondary":""}
    var node := _find_node(str(context["id"]))
    var ready := phase in ["dialogue", "prepare"]
    if placement_mode == "PLACE_NEW":
        actions["primary"] = "위치 지정 취소"
        actions["enabled"] = true
        actions["reason"] = "우측 전장의 빈 아군 칸을 선택하세요."
        return actions
    if str(context["kind"]) == "FIELD_INSTANCE":
        if ready:
            actions["primary"] = "배치 취소"
            actions["enabled"] = true
        else:
            actions["reason"] = "전투/결과 중에는 조회만 가능합니다."
        actions["secondary"] = "트리 병종 보기"
        return actions
    if str(node["kind"]) == "root":
        return actions
    if str(node["kind"]) != "unit" and _has_building(str(node["id"])):
        actions["secondary"] = "관련 병종 보기"
        return actions
    var unlocked := _is_node_unlocked(node)
    var slot_available := placements.size() < 12
    actions["enabled"] = ready and unlocked and (slot_available if str(node["kind"]) == "unit" else true)
    actions["primary"] = ("배치" if actions["enabled"] else "배치 불가") if str(node["kind"]) == "unit" else ("시연 건설" if actions["enabled"] else "건설 불가")
    var missing := _missing_requirement(node)
    if not missing.is_empty():
        actions["secondary"] = "필요 시설 찾기"
    elif str(node["kind"]) != "unit" and not _related_unit_ids(str(node["id"])).is_empty():
        actions["secondary"] = "관련 병종 보기"
    if not ready:
        actions["reason"] = "전투/결과 단계에서는 변경할 수 없습니다."
    elif week < int(node["week"]):
        actions["reason"] = "최소 W%02d 이후 시연 후보입니다." % int(node["week"])
    elif not missing.is_empty():
        actions["reason"] = "선행 시설이 필요합니다."
    elif str(node["kind"]) == "unit" and not slot_available:
        actions["reason"] = "최대 12기까지 배치할 수 있습니다."
    return actions


func _add_info_line(value: String, size: int = 19, tint: Color = UI.TEXT) -> void:
    var label := UI.make_label(value, size, tint)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size.x = 350
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info_column.add_child(label)


func _add_info_link(id: String, caption: String) -> void:
    var button := UI.make_button(caption, Vector2(350, 35))
    button.add_theme_font_size_override("font_size", 18)
    button.pressed.connect(_focus_requirement.bind(id))
    info_column.add_child(button)


func _related_unit_ids(building_id: String) -> Array[String]:
    var ids: Array[String] = []
    for node in NODES:
        if str(node["kind"]) != "unit":
            continue
        if building_id in node["requires"] or (building_id == "radar" and "drone_hangar" in node["requires"]):
            ids.append(str(node["id"]))
    return ids


func _unit_count(unit_id: String) -> int:
    var count := 0
    for entry in placements:
        if str(entry["unit_id"]) == unit_id:
            count += 1
    return count


func _render_info_content(context: Dictionary) -> void:
    var node := _find_node(str(context["id"]))
    var id := str(node["id"])
    var kind := str(node["kind"])
    _add_info_line(str(node["detail"]), 20)
    _add_info_line("최소 W%02d (시연 후보) · 현재 W%02d" % [int(node["week"]), week], 18, UI.GOLD)
    if kind != "unit":
        var parent_id := str(node["parent"])
        if not parent_id.is_empty():
            var parent := _find_node(parent_id)
            _add_info_line("선행: %s [%s]" % [str(parent["name"]), "보유" if _has_building(parent_id) else "미보유"], 18)
            _add_info_link(parent_id, "선행 시설: " + str(parent["name"]))
        if kind == "root":
            _add_info_line("본부 기본 보유 · 기술트리 시작 경로", 18)
            _add_info_line("직계 시설", 19, UI.GOLD)
            for child in NODES:
                if str(child["parent"]) == "hq":
                    _add_info_link(str(child["id"]), str(child["name"]))
        else:
            _add_info_line("즉시 완공 · 건설 비용 미정(시연)", 18, UI.MUTED)
            var linked_buildings: Array[String] = []
            for child in NODES:
                if str(child["parent"]) == id and str(child["kind"]) != "unit":
                    linked_buildings.append(str(child["id"]))
            if not linked_buildings.is_empty():
                _add_info_line("연결 시설", 19, UI.GOLD)
                for building_id in linked_buildings:
                    _add_info_link(building_id, str(_find_node(building_id)["name"]))
            var related := _related_unit_ids(id)
            if not related.is_empty():
                var names: Array[String] = []
                for related_id in related:
                    names.append(str(_find_node(related_id)["name"]))
                _add_info_line("연계 병종(별도 주차/시설 조건): " + ", ".join(PackedStringArray(names)), 18)
                if show_related_links:
                    for related_id in related:
                        _add_info_link(related_id, str(_find_node(related_id)["name"]))
        return
    _add_info_line("필수 시설", 19, UI.GOLD)
    for req in node["requires"]:
        var req_id := str(req)
        var required := _find_node(req_id)
        var owned := _has_building(req_id)
        _add_info_line("• %s [%s]" % [str(required["name"]), "보유" if owned else "미보유"], 18, UI.TEXT if owned else UI.MUTED)
        if not owned:
            _add_info_link(req_id, "필요 시설: " + str(required["name"]))
        var indirect_id := str(required["parent"])
        if not indirect_id.is_empty() and indirect_id != "hq" and indirect_id not in node["requires"]:
            var indirect := _find_node(indirect_id)
            _add_info_line("↳ 간접 선행: %s [%s]" % [str(indirect["name"]),
                "보유" if _has_building(indirect_id) else "미보유"], 17, UI.MUTED)
    _add_info_line("HP: 미구현 · 사거리: 미정", 18, UI.MUTED)
    _add_info_line("공격력/공격주기: 미정", 18, UI.MUTED)
    if str(context["kind"]) == "FIELD_INSTANCE":
        var entry: Dictionary = context["entry"]
        _add_info_line("개체 ID: " + str(entry["instance_id"]), 18, UI.GOLD)
        _add_info_line("배치 위치: 열 %d · 행 %d (아군)" % [int(entry["col"]) + 1, int(entry["row"]) + 1], 18)
    _add_info_line("배치 수: %d기 / 전체 %d·12기" % [_unit_count(id), placements.size()], 18)
    var upgrades: Array = UPGRADES.get(id, [])
    if upgrades.size() == 2:
        _add_info_line("고유 강화 · 조회 전용", 20, UI.GOLD)
        for i in range(2):
            var pair: Array = upgrades[i]
            _add_info_line("%s  %s — %s (제안)" % ["A" if i == 0 else "B", str(pair[0]), str(pair[1])], 18)
        _add_info_line("가격·구매·전투 효과 미확정", 17, UI.MUTED)


func _refresh_info_panel() -> void:
    if not is_instance_valid(info_column):
        return
    var context := _resolve_info_context()
    var node := _find_node(str(context["id"]))
    var info_key := "%s:%s:%s" % [str(context["kind"]), str(context["id"]), selected_instance_id]
    if info_content_key != info_key:
        info_content_key = info_key
        info_scroll.scroll_vertical = 0
    for child in info_column.get_children():
        info_column.remove_child(child)
        child.queue_free()
    var kind := str(node["kind"])
    info_title.text = str(node["name"]) + (" · 개체" if str(context["kind"]) == "FIELD_INSTANCE" else "")
    var class_name := "본부" if kind == "root" else ("유닛" if kind == "unit" else ("생산시설" if kind == "production" else "기술시설"))
    var status := "보유" if _has_building(str(node["id"])) else ("조건 충족" if _is_node_unlocked(node) else "잠금")
    if kind == "unit":
        status = "배치 가능" if _is_node_unlocked(node) else "배치 잠금"
        if phase not in ["dialogue", "prepare"]:
            status = "조회 전용"
    if placement_mode == "PLACE_NEW":
        status = "위치 지정 대기"
    if str(context["kind"]) == "FIELD_INSTANCE":
        status = "개체 선택 · " + ("배치 편집 가능" if phase in ["dialogue", "prepare"] else "조회 전용")
    info_status.text = class_name + " · " + status
    _render_info_content(context)
    var actions := _get_info_actions(context)
    deploy_button.visible = not str(actions["primary"]).is_empty()
    deploy_button.text = str(actions["primary"])
    deploy_button.disabled = not bool(actions["enabled"])
    secondary_button.visible = not str(actions["secondary"]).is_empty()
    secondary_button.text = str(actions["secondary"])
    info_reason.text = str(actions["reason"])


func _on_info_primary_action() -> void:
    var context := _resolve_info_context()
    var actions := _get_info_actions(context)
    if not bool(actions["enabled"]):
        if not str(actions["reason"]).is_empty():
            _append_log(str(actions["reason"]))
        return
    if placement_mode == "PLACE_NEW":
        _cancel_pending_placement()
    elif str(context["kind"]) == "FIELD_INSTANCE":
        _remove_placed_instance(str((context["entry"] as Dictionary)["instance_id"]))
    elif str(context["kind"]) == "TREE_UNIT":
        _begin_new_unit_placement(str(context["id"]))
    else:
        _build_selected()


func _on_info_secondary_action() -> void:
    var context := _resolve_info_context()
    var actions := _get_info_actions(context)
    match str(actions["secondary"]):
        "트리 병종 보기":
            _focus_requirement(str(context["id"]))
        "관련 병종 보기":
            _show_related_units(str(context["id"]))
        "필요 시설 찾기":
            var node := _find_node(str(context["id"]))
            var missing := _missing_requirement(node)
            if not missing.is_empty():
                _focus_requirement(missing)


func _focus_requirement(id: String) -> void:
    var node := _find_node(id)
    if node.is_empty():
        return
    if not _node_visible(node):
        full_tree_view = true
    _select_node(id)
    _refresh_all()


func _show_related_units(building_id: String) -> void:
    var context := _resolve_info_context()
    if str(context["id"]) != building_id or str(context["kind"]) != "TREE_BUILDING":
        return
    show_related_links = true
    _refresh_info_panel()


func _return_to_tree_context() -> void:
    selected_instance_id = ""
    if _find_node(selected_id).is_empty():
        selected_id = "hq"
    _refresh_info_panel()
    _queue_ui_redraw()


func _begin_new_unit_placement(unit_id: String) -> void:
    var node := _find_node(unit_id)
    if placement_mode != "NORMAL" or str(node.get("kind", "")) != "unit" or phase not in ["dialogue", "prepare"] or not _is_node_unlocked(node) or placements.size() >= 12 or not selected_instance_id.is_empty():
        return
    placement_mode = "PLACE_NEW"
    pending_unit_type_id = unit_id
    _append_log("%s: 우측 전장의 빈 아군 칸을 선택하세요." % str(node["name"]))
    _refresh_info_panel()
    _queue_ui_redraw()


func _cancel_pending_placement() -> void:
    if placement_mode != "PLACE_NEW":
        return
    placement_mode = "NORMAL"
    pending_unit_type_id = ""
    field_drag_armed = false
    _refresh_all()


func _remove_placed_instance(instance_id: String) -> void:
    if phase not in ["dialogue", "prepare"] or placement_mode != "NORMAL":
        return
    var index := _instance_index(instance_id)
    if index < 0 or instance_id != selected_instance_id:
        return
    var entry := placements[index]
    placements.remove_at(index)
    selected_instance_id = ""
    _append_log("%s 1기 배치 취소" % str(_find_node(str(entry["unit_id"]))["name"]))
    _refresh_all()


# Unapproved policies have explicit non-executing boundaries; no active UI calls these.
func _request_upgrade_purchase(_unit_id: String, _upgrade_key: String) -> bool:
    return false


func _request_building_refund(_building_id: String) -> bool:
    return false


func _request_paid_unit_production(_unit_id: String) -> bool:
    return false


func _request_range_overlay(_instance_id: String) -> bool:
    return false


func _request_combat_reposition(_instance_id: String, _cell: Vector2i) -> bool:
    return false


func _action_selected() -> void:
    _on_info_primary_action()


func _update_popup() -> void:
    _refresh_info_panel()

func _process(delta: float) -> void:
    if camera_offset.distance_squared_to(camera_target) > 0.5:
        camera_offset = _clamp_pan(camera_offset.lerp(camera_target, minf(1.0, delta * 9.0)))
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
    if INFO_PANEL_RECT.has_point(mouse):
        return ""
    if not _readable_tree_area().has_point(mouse - TREE_RECT.position):
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
    if event is InputEventMouseMotion and field_drag_armed:
        _update_field_drag((event as InputEventMouseMotion).position)
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseButton and field_drag_armed:
        var field_release := event as InputEventMouseButton
        if field_release.button_index == MOUSE_BUTTON_LEFT and not field_release.pressed:
            _finish_field_interaction(field_release.position)
            get_viewport().set_input_as_handled()
            return
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
        var hovered := _field_cell(mouse) if FIELD_RECT.has_point(mouse) else Vector2i(-1, -1)
        if hovered != field_hover_cell:
            field_hover_cell = hovered
            _queue_ui_redraw()
    elif event is InputEventMouseButton:
        var click := event as InputEventMouseButton
        if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
            return
        if INFO_PANEL_RECT.has_point(click.position):
            return
        if phase == "dialogue" and DIALOGUE_RECT.has_point(click.position):
            _advance_dialogue()
            return
        if TREE_RECT.has_point(click.position):
            if Rect2(Vector2(22, 100), Vector2(188, 52)).has_point(click.position):
                return
            _start_pan(click.position)
        elif FIELD_RECT.has_point(click.position):
            _start_field_interaction(click.position)

func _advance_dialogue() -> void:
    if phase != "dialogue":
        return
    dialogue_index += 1
    if week == 1 and dialogue_index == 3 and not user_selected_context and selected_id == "hq" and selected_instance_id.is_empty():
        _select_node("rifle", false) # Tutorial only; never overrides explicit user selection.
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
    _begin_new_unit_placement(selected_id)


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
    if placement_mode == "PLACE_NEW":
        _cancel_pending_placement()
    g -= DEMO_BATTLE_COST
    phase = "battle"
    battle_seconds = 0
    _append_log("전투가 시작되었습니다. (시연)")
    _refresh_all()


func _grid_origin() -> Vector2:
    var sz := _grid_size()
    return FIELD_RECT.position + (FIELD_RECT.size - Vector2(sz) * GRID_CELL_SIZE) * 0.5


func _field_cell(mouse: Vector2) -> Vector2i:
    if not FIELD_RECT.has_point(mouse):
        return Vector2i(-1, -1)
    var sz := _grid_size()
    var cell := Vector2i(((mouse - _grid_origin()) / GRID_CELL_SIZE).floor())
    if cell.x < 0 or cell.y < 0 or cell.x >= sz.x or cell.y >= sz.y:
        return Vector2i(-1, -1)
    return cell


func _is_ally_cell(cell: Vector2i) -> bool:
    var sz := _grid_size()
    return cell.x >= 0 and cell.x < sz.x and cell.y >= int(sz.y / 2) and cell.y < sz.y


func _instance_index(instance_id: String) -> int:
    if instance_id.is_empty():
        return -1
    for i in range(placements.size()):
        if str(placements[i]["instance_id"]) == instance_id:
            return i
    return -1


func _instance_at_cell(cell: Vector2i) -> int:
    if not _is_ally_cell(cell):
        return -1
    for i in range(placements.size()):
        var entry: Dictionary = placements[i]
        if int(entry["col"]) == cell.x and int(entry["row"]) == cell.y:
            return i
    return -1


func _start_field_interaction(mouse: Vector2) -> void:
    camera_target = camera_offset # A field drag must never continue an earlier tree focus.
    field_drag_armed = true
    field_dragging = false
    field_drag_start = mouse
    field_drag_cell = _field_cell(mouse)
    field_hover_cell = field_drag_cell
    var found := _instance_at_cell(field_drag_cell)
    field_drag_instance_id = str(placements[found]["instance_id"]) if found >= 0 else ""
    _queue_ui_redraw()


func _update_field_drag(mouse: Vector2) -> void:
    if not field_drag_armed:
        return
    if not field_dragging and mouse.distance_to(field_drag_start) < DRAG_THRESHOLD:
        return
    field_dragging = true
    field_drag_cell = _field_cell(mouse)
    _queue_ui_redraw()


func _tree_node_readable(node: Dictionary) -> bool:
    var bounds := _node_visual_rect(node)
    return _readable_tree_area().encloses(Rect2(bounds.position + camera_offset, bounds.size))


func _select_field_instance(instance_id: String) -> void:
    var index := _instance_index(instance_id)
    if index < 0:
        return
    selected_instance_id = instance_id
    user_selected_context = true
    show_related_links = false
    var node := _find_node(str(placements[index]["unit_id"]))
    if not _node_visible(node):
        full_tree_view = true
    if not field_dragging and not _tree_node_readable(node):
        camera_target = _clamp_pan(TREE_CENTER_LOCAL - node["p"])
    _refresh_all()


func _confirm_pending_at(cell: Vector2i) -> bool:
    if placement_mode != "PLACE_NEW" or phase not in ["dialogue", "prepare"]:
        return false
    var node := _find_node(pending_unit_type_id)
    if node.is_empty() or str(node["kind"]) != "unit" or not _is_node_unlocked(node) or placements.size() >= 12:
        _append_log("배치 조건이 더 이상 충족되지 않습니다.")
        return false
    if not _is_ally_cell(cell):
        _append_log("아군 배치 영역의 칸을 선택하세요.")
        return false
    if _instance_at_cell(cell) >= 0:
        _append_log("이미 다른 유닛이 있는 칸입니다.")
        return false
    var instance_id := "unit_%06d" % next_instance_serial
    while _instance_index(instance_id) >= 0:
        next_instance_serial += 1
        instance_id = "unit_%06d" % next_instance_serial
    next_instance_serial += 1
    placements.append({"instance_id":instance_id, "unit_id":pending_unit_type_id,
        "col":cell.x, "row":cell.y})
    placement_mode = "NORMAL"
    pending_unit_type_id = ""
    _select_field_instance(instance_id)
    _append_log("%s 1기 배치 완료" % str(node["name"]))
    return true


func _finish_field_interaction(mouse: Vector2) -> void:
    if not field_drag_armed:
        return
    # The release point can move past the threshold without an intermediate motion event.
    var dragged := field_dragging or mouse.distance_to(field_drag_start) >= DRAG_THRESHOLD
    var instance_id := field_drag_instance_id
    field_drag_armed = false
    field_dragging = false
    field_drag_instance_id = ""
    var cell := _field_cell(mouse)
    field_drag_cell = Vector2i(-1, -1)
    if placement_mode == "PLACE_NEW":
        if not dragged:
            _confirm_pending_at(cell)
        _queue_ui_redraw()
        return
    if instance_id.is_empty():
        if not dragged and _is_ally_cell(cell):
            _return_to_tree_context()
        return
    var index := _instance_index(instance_id)
    if index < 0:
        return
    if dragged and phase in ["dialogue", "prepare"]:
        if not _is_ally_cell(cell):
            _append_log("아군 영역 밖으로 이동할 수 없습니다.")
        elif _instance_at_cell(cell) >= 0 and _instance_at_cell(cell) != index:
            _append_log("해당 칸에 다른 유닛이 있습니다.")
        else:
            var entry: Dictionary = placements[index]
            entry["col"] = cell.x
            entry["row"] = cell.y
            placements[index] = entry
    _select_field_instance(instance_id)


func _click_ally(mouse: Vector2) -> void:
    # Compatibility entry point: one complete click, not an index-based selection.
    _start_field_interaction(mouse)
    _finish_field_interaction(mouse)

static func grid_size_for_week(at_week: int) -> Vector2i:
    if at_week <= 13:
        return Vector2i(6, 6)
    if at_week <= 26:
        return Vector2i(8, 8)
    if at_week <= 39:
        return Vector2i(10, 8)
    return Vector2i(10, 10)


static func legacy_cell_for_index(index: int, at_week: int) -> Vector2i:
    var sz := grid_size_for_week(at_week)
    return Vector2i(1 + index % (sz.x - 2), sz.y - 1 - int(index / (sz.x - 2)))


func _grid_size() -> Vector2i:
    return grid_size_for_week(week)


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
    battle_button.disabled = phase == "dialogue" or phase == "battle" or (phase == "result" and week == MAX_WEEK)
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
        return "아군을 클릭해 개별 정보를 보고, 준비 중 드래그로 이동하세요."
    if help_index == 35:
        return "전투 속도는 1× 또는 2×로 변경할 수 있습니다."
    if help_index == 52:
        return "지난 도움말은 왼쪽 화살표로 다시 볼 수 있습니다."
    return "%d주차: 빌드와 전장 배치를 점검하세요." % help_index


func _draw_tree() -> void:
    # Only the 20 structural nodes render here. The 24 upgrades are drawn
    # within the fixed information panel, never as extra tree nodes.
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
        var focused := id == _active_tree_node_id()
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


func _draw_field() -> void:
    var sz := _grid_size()
    var cols: int = sz.x
    var rows: int = sz.y
    var start := _grid_origin()
    for r in range(rows):
        for c in range(cols):
            var pos := start + Vector2(c, r) * GRID_CELL_SIZE
            var cell := Vector2i(c, r)
            var fill: Color = UI.ENEMY_CELL if r < int(rows / 2) else UI.ALLY_CELL
            _box(Rect2(pos, Vector2.ONE * GRID_CELL_SIZE), fill, UI.GRID_BORDER)
            if placement_mode == "PLACE_NEW" and _is_ally_cell(cell) and _instance_at_cell(cell) < 0:
                draw_rect(Rect2(pos + Vector2.ONE * 3.0, Vector2.ONE * (GRID_CELL_SIZE - 6.0)),
                    UI.TEAL, false, 2.0)
    var mid_y: float = start.y + float(rows / 2) * GRID_CELL_SIZE
    draw_line(Vector2(start.x, mid_y), Vector2(start.x + cols * GRID_CELL_SIZE, mid_y), UI.TEXT, 2.0)
    for i in range(3):
        var enemy_p := start + Vector2((1 + i * 2) * GRID_CELL_SIZE + 8, (0 if i < 2 else 1) * GRID_CELL_SIZE + 8)
        draw_rect(Rect2(enemy_p, Vector2(30, 30)), UI.ENEMY)
        _text("×", enemy_p + Vector2(6, -4), 28)
    for entry in placements:
        var cell := Vector2i(int(entry["col"]), int(entry["row"]))
        var ally_p := start + Vector2(cell) * GRID_CELL_SIZE + Vector2(8, 8)
        draw_rect(Rect2(ally_p, Vector2(30, 30)), UI.TEAL)
        _text("■", ally_p + Vector2(3, -2), 25, UI.BACKGROUND)
        if str(entry["instance_id"]) == selected_instance_id:
            draw_rect(Rect2(ally_p - Vector2.ONE * 5.0, Vector2(40, 40)), UI.GOLD, false, 3.0)
    if placement_mode == "PLACE_NEW" and _is_ally_cell(field_hover_cell):
        var candidate := start + Vector2(field_hover_cell) * GRID_CELL_SIZE
        var valid := _instance_at_cell(field_hover_cell) < 0
        draw_rect(Rect2(candidate + Vector2.ONE * 2.0, Vector2.ONE * (GRID_CELL_SIZE - 4.0)),
            UI.GOLD if valid else UI.ENEMY, false, 4.0)
    elif phase in ["dialogue", "prepare"] and field_drag_armed and field_dragging and not field_drag_instance_id.is_empty() and _is_ally_cell(field_drag_cell):
        var destination := start + Vector2(field_drag_cell) * GRID_CELL_SIZE
        var occupant := _instance_at_cell(field_drag_cell)
        var valid := occupant < 0 or str(placements[occupant]["instance_id"]) == field_drag_instance_id
        draw_rect(Rect2(destination + Vector2.ONE * 2.0, Vector2.ONE * (GRID_CELL_SIZE - 4.0)),
            UI.GOLD if valid else UI.ENEMY, false, 4.0)

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

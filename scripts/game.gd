extends Control
## W52 16:9 fixed-ratio battle/build UI. Prototype combat/economy values are illustrative,
## NOT approved gameplay balance or the final battle simulation.
signal defeated

const UI = preload("res://scripts/ui_style.gd")
const FONT: Font = preload("res://assets/fonts/ui_ko_subset.woff2")
# Pixel UI Fantasy Free: selectively used art, kept separate from the global UI theme.
const PIXEL_PANEL: Texture2D = preload("res://assets/ui/pixel_fantasy/frame.png")
const PIXEL_SLOT: Texture2D = preload("res://assets/ui/pixel_fantasy/slot.png")
const PIXEL_SLOT_ACTIVE: Texture2D = preload("res://assets/ui/pixel_fantasy/slot_active.png")
const ICON_GEM: Texture2D = preload("res://assets/ui/pixel_fantasy/gem.png")
const ICON_SCROLL: Texture2D = preload("res://assets/ui/pixel_fantasy/scroll.png")
const ICON_SHIELD: Texture2D = preload("res://assets/ui/pixel_fantasy/shield.png")
const ICON_ARROW: Texture2D = preload("res://assets/ui/pixel_fantasy/arrow_right.png")
const ICON_CHEST: Texture2D = preload("res://assets/ui/pixel_fantasy/chest.png")
const ICON_SWORD: Texture2D = preload("res://assets/ui/pixel_fantasy/sword.png")
const ICON_LOCK: Texture2D = preload("res://assets/ui/pixel_fantasy/lock.png")
# Worn survival terminal trim; battlefield units remain deliberately untouched.
const PIXEL_PORTRAIT: Texture2D = preload("res://assets/ui/pixel_fantasy/portrait.png")
const PIXEL_NAMEPLATE: Texture2D = preload("res://assets/ui/pixel_fantasy/nameplate.png")
const PIXEL_WINDOW: Texture2D = preload("res://assets/ui/pixel_fantasy/window.png")
const PIXEL_TOOLTIP: Texture2D = preload("res://assets/ui/pixel_fantasy/tooltip.png")
const PIXEL_INSET: Texture2D = preload("res://assets/ui/pixel_fantasy/panel_inset.png")
const PIXEL_PARCHMENT: Texture2D = preload("res://assets/ui/pixel_fantasy/parchment.png")
const PIXEL_DIVIDER: Texture2D = preload("res://assets/ui/pixel_fantasy/divider.png")
const PIXEL_RIBBON: Texture2D = preload("res://assets/ui/pixel_fantasy/ribbon.png")
const ICON_COIN: Texture2D = preload("res://assets/ui/pixel_fantasy/coin.png")
const ICON_QUEST: Texture2D = preload("res://assets/ui/pixel_fantasy/quest.png")
const PIXEL_PROGRESS_BG: Texture2D = preload("res://assets/ui/pixel_fantasy/progress_bg.png")
const PIXEL_PROGRESS_FILL: Texture2D = preload("res://assets/ui/pixel_fantasy/progress_fill.png")
const PIXEL_SCALE := 3.0
const NODE_FRAME_SIZE := 75.0
const NODE_FRAME_SELECTED_SIZE := 84.0 # Exactly 1.12x, both integer pixel sizes
const NODE_ICON_SIZE := 48.0
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
    {"id":"root", "name":"지휘 본부", "kind":"root", "parent":"", "p":Vector2(670, 744), "week":1, "symbol":"◆", "detail":"전략의 시작 노드입니다."},
    {"id":"command", "name":"초기 전술", "kind":"branch", "parent":"root", "p":Vector2(670, 612), "week":1, "symbol":"◇", "detail":"기본 지휘 분기입니다."},
    {"id":"guard", "name":"방패병", "kind":"unit", "parent":"command", "p":Vector2(895, 454), "week":1, "symbol":"■", "detail":"전선 유지에 특화된|아군 전투 유닛입니다."},
    {"id":"scout", "name":"정찰병", "kind":"unit", "parent":"command", "p":Vector2(430, 454), "week":8, "symbol":"◆", "detail":"전방 이동을 담당하는|아군 전투 유닛입니다."},
    {"id":"mobility", "name":"기동 전술", "kind":"upgrade", "parent":"scout", "p":Vector2(244, 292), "week":17, "symbol":"↗", "detail":"기동 연구 경로입니다."},
    {"id":"supply", "name":"보급 체계", "kind":"branch", "parent":"command", "p":Vector2(674, 292), "week":26, "symbol":"◇", "detail":"전력 운용 연구 분기입니다."},
    {"id":"drone", "name":"포격 드론", "kind":"unit", "parent":"guard", "p":Vector2(1095, 292), "week":29, "symbol":"◎", "detail":"후방 지원을 담당하는|아군 전투 유닛입니다."},
    {"id":"elite", "name":"전술 분대", "kind":"unit", "parent":"supply", "p":Vector2(841, 133), "week":44, "symbol":"■", "detail":"후반 확장 전투 유닛입니다."}
]

var week: int = 1
var g: int = 160
var phase: String = "dialogue" # dialogue, prepare, battle, result
var dialogue_index: int = 0
var help_index: int = 1
var selected_id: String = ""
var hover_id: String = ""
var placements: Array[String] = []
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
var pixel_panel_border: StyleBoxTexture
var pixel_slot_border: StyleBoxTexture
var pixel_slot_border_active: StyleBoxTexture
var pixel_window_border: StyleBoxTexture
var pixel_portrait_border: StyleBoxTexture
var pixel_nameplate_border: StyleBoxTexture
var pixel_tooltip_border: StyleBoxTexture
var pixel_inset_border: StyleBoxTexture
var pixel_parchment_border: StyleBoxTexture
var pixel_divider_border: StyleBoxTexture
var pixel_ribbon_border: StyleBoxTexture
var pixel_progress_bg: StyleBoxTexture
var pixel_progress_fill: StyleBoxTexture
var pixel_coin: Texture2D
var pixel_quest: Texture2D
var pixel_icons: Dictionary
var popup_surface: Control
var dialogue_surface: Control


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    # 3x source pixels in the 1920x1080 layout are 2x at the 1280x720 default window.
    # Do not change the game resolution, transforms, input geometry, or Korean font.
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    pixel_panel_border = _pixel_style_box(PIXEL_PANEL, 6, false)
    pixel_slot_border = _pixel_style_box(PIXEL_SLOT, 3, true)
    pixel_slot_border_active = _pixel_style_box(PIXEL_SLOT_ACTIVE, 3, true)
    pixel_window_border = _pixel_slices(PIXEL_WINDOW, Vector4i(6, 19, 6, 6), false)
    pixel_portrait_border = _pixel_style_box(PIXEL_PORTRAIT, 9, false)
    pixel_nameplate_border = _pixel_slices(PIXEL_NAMEPLATE, Vector4i(5, 4, 5, 4))
    pixel_tooltip_border = _pixel_style_box(PIXEL_TOOLTIP, 3, false)
    pixel_inset_border = _pixel_style_box(PIXEL_INSET, 5, false)
    pixel_parchment_border = _pixel_slices(PIXEL_PARCHMENT, Vector4i(6, 9, 6, 9))
    pixel_divider_border = _pixel_slices(PIXEL_DIVIDER, Vector4i(8, 0, 8, 0))
    pixel_ribbon_border = _pixel_slices(PIXEL_RIBBON, Vector4i(9, 3, 9, 5))
    pixel_progress_bg = _pixel_slices(PIXEL_PROGRESS_BG, Vector4i(4, 3, 4, 3))
    pixel_progress_fill = _pixel_slices(PIXEL_PROGRESS_FILL, Vector4i(5, 2, 5, 2))
    pixel_coin = _pixel_texture(ICON_COIN)
    pixel_quest = _pixel_texture(ICON_QUEST)
    pixel_icons = {
        "root": _pixel_texture(ICON_GEM),
        "command": _pixel_texture(ICON_SCROLL),
        "guard": _pixel_texture(ICON_SHIELD),
        "scout": _pixel_texture(ICON_ARROW),
        "mobility": _pixel_texture(ICON_ARROW),
        "supply": _pixel_texture(ICON_CHEST),
        "elite": _pixel_texture(ICON_SWORD),
        "locked": _pixel_texture(ICON_LOCK),
    }
    _create_controls()
    _set_week_intro()
    _refresh_all()


func restore_state(data: Dictionary) -> void:
    week = clampi(int(data.get("week", 1)), 1, MAX_WEEK)
    g = maxi(0, int(data.get("g", 160)))
    var requested: String = str(data.get("phase", "dialogue"))
    phase = requested if requested in ["dialogue", "prepare", "battle", "result"] else "dialogue"
    if phase == "battle":
        phase = "prepare" # A paused-in-battle snapshot resumes from preparation, not a half simulated fight.
    dialogue_index = clampi(int(data.get("dialogue", 0)), 0, DIALOGUE_COUNT)
    help_index = clampi(int(data.get("help", week)), 1, week)
    placements.clear()
    var saved_placements: Variant = data.get("placements", [])
    if saved_placements is Array:
        for item in saved_placements:
            var node := _find_node(str(item))
            if not node.is_empty() and str(node["kind"]) == "unit" and int(node["week"]) <= week and placements.size() < 12:
                placements.append(str(item))
    if phase == "dialogue" and dialogue_index >= DIALOGUE_COUNT:
        phase = "prepare"
    selected_id = ""
    camera_offset = Vector2.ZERO
    camera_target = Vector2.ZERO
    log_items = ["%d주차 전투 준비 중입니다." % week]
    for id in placements:
        log_items.append("%s 배치됨" % str(_find_node(id)["name"]))
    _refresh_all()


func snapshot() -> Dictionary:
    return {"week":week, "g":g, "phase":phase, "dialogue":dialogue_index,
        "help":help_index, "placements":placements.duplicate()}


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

    deploy_button = UI.make_button("배치", Vector2(160, 62))
    deploy_button.position = Vector2(-500, -500)
    deploy_button.size = Vector2(160, 62)
    deploy_button.add_theme_font_size_override("font_size", 26)
    deploy_button.pressed.connect(_deploy_selected)
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
    UI.decorate_log_scroll(log_scroll.get_v_scroll_bar())
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
    camera_target = Vector2.ZERO
    camera_offset = Vector2.ZERO
    pan_armed = false
    pan_dragging = false
    battle_seconds = 0.0
    log_items = ["%d주차 전투 준비 중입니다." % week]


func _find_node(id: String) -> Dictionary:
    for item in NODES:
        if str(item["id"]) == id:
            return item
    return {}


func _node_tree_local(node: Dictionary) -> Vector2:
    return node["p"] + camera_offset


func _node_screen(node: Dictionary) -> Vector2:
    return TREE_RECT.position + _node_tree_local(node)


func _selected_ancestors() -> Array[String]:
    var result: Array[String] = []
    var current: String = selected_id
    while not current.is_empty():
        result.append(current)
        var node := _find_node(current)
        if node.is_empty():
            break
        current = str(node["parent"])
    return result


func _node_visual_rect(node: Dictionary) -> Rect2:
    # A recognizable unit of the tree is one entire node plus its name label.
    # Use its largest hover/selection icon size and the measured label width.
    var p: Vector2 = node["p"]
    # Account for the nearest 3px snap when guaranteeing a complete visible node.
    var radius := maxf(38.0 * 1.12, NODE_FRAME_SELECTED_SIZE * 0.5 + PIXEL_SCALE * 0.5)
    var label_width := FONT.get_string_size(str(node["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
    var left := minf(p.x - radius, p.x - 40.0)
    var right := maxf(p.x + radius, p.x - 40.0 + label_width)
    var top := p.y - radius
    var bottom := p.y + radius + 7.0 + 22.0 + FONT.get_descent(22)
    return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


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
        var artwork := _node_visual_rect(node)
        var min_offset := visible.position - artwork.position
        var max_offset := visible.end - artwork.end
        var projected := candidate.clamp(min_offset, max_offset)
        var distance := candidate.distance_squared_to(projected)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = projected
    return nearest


func _select_node(id: String) -> void:
    var node := _find_node(id)
    if node.is_empty():
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
    deploy_button.visible = str(node["kind"]) == "unit"
    deploy_button.disabled = int(node["week"]) > week or phase == "battle" or phase == "result"
    deploy_button.text = "배치" if not deploy_button.disabled else "배치 불가"


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
    if not selected_id.is_empty() and _popup_rect().has_point(mouse):
        return ""
    for node in NODES:
        if _node_screen(node).distance_to(mouse) <= 49.0:
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
            if not selected_id.is_empty() and _popup_rect().has_point(click.position):
                return
            _start_pan(click.position)
        elif Rect2(1376, 84, 544, 652).has_point(click.position):
            _click_ally(click.position)


func _advance_dialogue() -> void:
    if phase != "dialogue":
        return
    dialogue_index += 1
    if dialogue_index == 3:
        _select_node("guard") # Dialogue completion can select/focus tree nodes.
    elif dialogue_index >= DIALOGUE_COUNT:
        phase = "prepare"
    _refresh_all()


func _dialogue_content() -> Array[String]:
    if week == 1:
        return [
            "52주 동안 주마다 한 차례 전투를 준비합니다.",
            "왼쪽의 노드에서 사용할 전략을 살펴보세요.",
            "방패병 경로가 선택되었습니다.",
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
    if node.is_empty() or str(node["kind"]) != "unit" or int(node["week"]) > week:
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
    prev_button.disabled = help_index <= 1
    next_button.disabled = help_index >= week
    speed_one.button_pressed = speed == 1
    speed_two.button_pressed = speed == 2
    speed_one.add_theme_color_override("font_color", UI.BACKGROUND if speed == 1 else UI.TEXT)
    speed_one.add_theme_color_override("font_hover_color", UI.BACKGROUND)
    speed_one.add_theme_stylebox_override("normal", UI.style_speed_tab(speed == 1))
    speed_one.add_theme_stylebox_override("hover", UI.style_speed_hover())
    speed_one.add_theme_stylebox_override("pressed", UI.style_speed_tab(speed == 1))
    speed_two.add_theme_color_override("font_color", UI.BACKGROUND if speed == 2 else UI.TEXT)
    speed_two.add_theme_color_override("font_hover_color", UI.BACKGROUND)
    speed_two.add_theme_stylebox_override("normal", UI.style_speed_tab(speed == 2))
    speed_two.add_theme_stylebox_override("hover", UI.style_speed_hover())
    speed_two.add_theme_stylebox_override("pressed", UI.style_speed_tab(speed == 2))
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
    surface.draw_style_box(pixel_panel_border, _pixel_rect(rect))


func _queue_ui_redraw() -> void:
    queue_redraw()
    if is_instance_valid(tree_surface):
        tree_canvas.queue_redraw()
    if is_instance_valid(popup_surface):
        popup_surface.queue_redraw()
    if is_instance_valid(dialogue_surface):
        dialogue_surface.queue_redraw()


func _box(rect: Rect2, fill: Color, border: Color = UI.BORDER) -> void:
    # Battlefield cell borders remain thin and color-coded.
    draw_rect(rect, fill)
    draw_rect(rect, border, false, 2.0)


func _pixel_texture(source: Texture2D) -> Texture2D:
    # Copy imported source pixels before enlarging; never resize shared resources.
    var image: Image = source.get_image().duplicate() as Image
    image.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
    return ImageTexture.create_from_image(image)


func _pixel_style_box(source: Texture2D, source_margin: int, with_center: bool) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = _pixel_texture(source)
    style.set_texture_margin_all(float(source_margin) * PIXEL_SCALE)
    style.draw_center = with_center
    style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    return style


func _pixel_slices(source: Texture2D, margins: Vector4i, center: bool = true) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = _pixel_texture(source)
    style.texture_margin_left = margins.x * PIXEL_SCALE
    style.texture_margin_top = margins.y * PIXEL_SCALE
    style.texture_margin_right = margins.z * PIXEL_SCALE
    style.texture_margin_bottom = margins.w * PIXEL_SCALE
    style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    style.draw_center = center
    return style


func _pixel_rect(rect: Rect2) -> Rect2:
    # Keep border endpoints on exact 3px logical-pixel grid.
    var start := (rect.position / PIXEL_SCALE).round() * PIXEL_SCALE
    var finish := (rect.end / PIXEL_SCALE).round() * PIXEL_SCALE
    return Rect2(start, finish - start)


func _framed_box(rect: Rect2, fill: Color) -> void:
    draw_rect(rect, fill)
    draw_style_box(pixel_panel_border, _pixel_rect(rect))


func _draw() -> void:
    # Fixed HUD background is drawn at the root; TreeArt renders in a clipped
    # child Control and can never paint into the battlefield or other panels.
    draw_rect(Rect2(0, 0, 1920, 1080), UI.BACKGROUND)
    _framed_box(TREE_RECT, UI.GAME_BACKGROUND)
    for x in range(0, 1376, 56):
        draw_line(Vector2(x, 84), Vector2(x, 976), UI.GRID, 1.0)
    for y in range(84, 976, 56):
        draw_line(Vector2(0, y), Vector2(1376, y), UI.GRID, 1.0)
    _framed_box(Rect2(0, 0, 1376, 84), UI.HEADER)
    _framed_box(Rect2(1376, 0, 544, 84), UI.HEADER)
    _framed_box(Rect2(0, 976, 1376, 104), UI.PANEL)
    _framed_box(Rect2(1376, 84, 544, 652), UI.GAME_BACKGROUND)
    _framed_box(Rect2(1376, 736, 544, 240), UI.PANEL)
    _framed_box(Rect2(1376, 976, 544, 104), UI.PANEL)
    _text("%02d주차" % week, Vector2(44, 16), 38)
    draw_line(Vector2(233, 17), Vector2(233, 67), UI.BORDER, 2)
    draw_texture(pixel_coin, Vector2(264, 18))
    _text("%s G" % _group_digits(g), Vector2(320, 17), 37, UI.GOLD)
    # Week 1 starts empty; finishing week 52 fills the survival timeline.
    var survived := (week if phase == "result" else week - 1)
    var progress := float(survived) / float(MAX_WEEK)
    var progress_bg := Rect2(710, 27, 588, 30)
    draw_style_box(pixel_progress_bg, _pixel_rect(progress_bg))
    if survived > 0:
        var fill_width := maxf(33.0, 588.0 * progress)
        draw_style_box(pixel_progress_fill, _pixel_rect(Rect2(710, 27, fill_width, 30)))
    var secs := int(battle_seconds)
    _text("%02d:%02d" % [secs / 60, secs % 60], Vector2(1410, 16), 36)
    _draw_field()
    # Recessed battle-report terminal; ScrollContainer remains the only scroll area.
    draw_style_box(pixel_inset_border, _pixel_rect(Rect2(1393, 792, 504, 177)))
    draw_texture(pixel_quest, Vector2(1401, 741))
    _text("전투 정보", Vector2(1455, 747), 28)
    draw_style_box(pixel_divider_border, _pixel_rect(Rect2(1401, 784, 492, 21)))
    # Survival field manual. Dark text contrasts with the source parchment.
    draw_style_box(pixel_parchment_border, _pixel_rect(Rect2(240, 984, 992, 81)))
    draw_style_box(pixel_ribbon_border, _pixel_rect(Rect2(104, 987, 132, 63)))
    _text("도움말", Vector2(121, 998), 23, UI.TEXT)
    _text(_help_text(), Vector2(270, 1007), 25, Color("#33241c"))


func _group_digits(value: int) -> String:
    var s := str(value)
    var output := ""
    while s.length() > 3:
        output = "," + s.substr(s.length() - 3) + output
        s = s.substr(0, s.length() - 3)
    return s + output


func _help_text() -> String:
    if help_index == 1:
        return "노드를 선택하고 유닛을 배치하세요."
    if help_index == 18:
        return "아군을 클릭하면 연결된 트리 노드로 포커스됩니다."
    if help_index == 35:
        return "전투 속도는 1× 또는 2×로 변경할 수 있습니다."
    if help_index == 52:
        return "지난 도움말은 왼쪽 화살표로 다시 볼 수 있습니다."
    return "%d주차: 빌드와 전장 배치를 점검하세요." % help_index


func _draw_tree() -> void:
    # Local coordinates, rendered exclusively inside TreeClip.clip_contents.
    var path := _selected_ancestors()
    for node in NODES:
        var parent_id := str(node["parent"])
        if parent_id.is_empty():
            continue
        var parent := _find_node(parent_id)
        var a := _node_tree_local(parent)
        var b := _node_tree_local(node)
        var middle_y := (a.y + b.y) * 0.5
        var highlight := str(node["id"]) in path and parent_id in path
        var tint := UI.TEAL if highlight else UI.TREE_LINE
        tree_canvas.draw_polyline(PackedVector2Array([a - Vector2(0, 35), Vector2(a.x, middle_y),
            Vector2(b.x, middle_y), b + Vector2(0, 35)]), tint, 5.0 if highlight else 3.5, true)
    for node in NODES:
        var p := _node_tree_local(node)
        if p.y < -100 or p.y > TREE_RECT.size.y + 100 or p.x < -100 or p.x > TREE_RECT.size.x + 100:
            continue
        var id := str(node["id"])
        var locked := int(node["week"]) > week
        var focused := id == selected_id
        var hovered := id == hover_id
        var radius := 38.0 * (1.12 if focused or hovered else 1.0)
        # 75px normal / 84px selected makes the 1.12x effect pixel-exact.
        var frame_size := NODE_FRAME_SELECTED_SIZE if focused or hovered else NODE_FRAME_SIZE
        var frame_rect := _pixel_rect(Rect2(p - Vector2.ONE * (frame_size * 0.5),
            Vector2.ONE * frame_size))
        tree_canvas.draw_style_box(
            pixel_slot_border_active if focused or hovered else pixel_slot_border, frame_rect)
        # A locked node shows a lock. The drone has no matching icon in the free pack,
        # so keep its existing placeholder symbol rather than mislabel its function.
        var icon: Texture2D = pixel_icons.get("locked" if locked else id) as Texture2D
        if icon != null:
            var icon_pos := (frame_rect.position + Vector2.ONE * ((frame_size - NODE_ICON_SIZE) * 0.5))
            icon_pos = (icon_pos / PIXEL_SCALE).round() * PIXEL_SCALE
            tree_canvas.draw_texture(icon, icon_pos)
        else:
            _layer_text(tree_canvas, str(node["symbol"]), p + Vector2(-13, -22), 31, UI.GOLD)
        _layer_text(tree_canvas, str(node["name"]), p + Vector2(-40, radius + 7), 22, UI.MUTED if locked else UI.TEXT)


func _draw_popup() -> void:
    if selected_id.is_empty():
        return
    var node := _find_node(selected_id)
    if node.is_empty():
        return
    var panel := _popup_rect()
    popup_surface.draw_rect(panel, UI.PANEL)
    popup_surface.draw_style_box(pixel_window_border, _pixel_rect(panel))
    _layer_text(popup_surface, str(node["name"]), panel.position + Vector2(25, 15), 32)
    var details_rect := Rect2(panel.position + Vector2(15, 74), Vector2(360, 109))
    popup_surface.draw_rect(details_rect, UI.PANEL.darkened(0.18))
    popup_surface.draw_style_box(pixel_tooltip_border, _pixel_rect(details_rect))
    var details := str(node["detail"]).split("|")
    for i in range(details.size()):
        _layer_text(popup_surface, str(details[i]), panel.position + Vector2(25, 92 + i * 37), 25, UI.MUTED)


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
    var portrait_rect := Rect2(52, 800, 112, 125)
    dialogue_surface.draw_rect(portrait_rect, UI.NODE_FILL)
    dialogue_surface.draw_style_box(pixel_portrait_border, _pixel_rect(portrait_rect))
    # A placeholder radio-operator glyph: never pretend it is a character portrait.
    var speaker := "해설" if dialogue_index == 0 or dialogue_index == 2 or dialogue_index == 4 else "작전 참모"
    _layer_text(dialogue_surface, "≡" if speaker == "해설" else "◆", Vector2(83, 815), 48, UI.GOLD)
    dialogue_surface.draw_style_box(pixel_nameplate_border, _pixel_rect(Rect2(182, 789, 266, 54)))
    _layer_text(dialogue_surface, speaker, Vector2(205, 799), 26, UI.TEXT)
    var text_lines := _dialogue_content()
    _layer_text(dialogue_surface, text_lines[min(dialogue_index, DIALOGUE_COUNT - 1)], Vector2(196, 845), 28)
    _layer_text(dialogue_surface, "Space  다음 ›", Vector2(1137, 905), 21, UI.MUTED)

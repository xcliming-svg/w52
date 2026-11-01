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

var deploy_button: Button
var battle_button: Button
var prev_button: Button
var next_button: Button
var speed_one: Button
var speed_two: Button
var log_scroll: ScrollContainer
var log_column: VBoxContainer


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
    deploy_button = UI.make_button("배치")
    deploy_button.position = Vector2(-500, -500)
    deploy_button.custom_minimum_size = Vector2.ZERO
    deploy_button.size = Vector2(160, 62)
    deploy_button.add_theme_font_size_override("font_size", 26)
    deploy_button.pressed.connect(_deploy_selected)
    add_child(deploy_button)

    prev_button = UI.make_button("〈")
    next_button = UI.make_button("〉")
    for b in [prev_button, next_button]:
        b.custom_minimum_size = Vector2.ZERO
        b.size = Vector2(72, 64)
        b.add_theme_font_size_override("font_size", 32)
        add_child(b)
    prev_button.position = Vector2(26, 995)
    next_button.position = Vector2(1278, 995)
    prev_button.pressed.connect(func() -> void: _change_help(-1))
    next_button.pressed.connect(func() -> void: _change_help(1))

    speed_one = UI.make_button("1×")
    speed_two = UI.make_button("2×")
    for b in [speed_one, speed_two]:
        b.custom_minimum_size = Vector2.ZERO
        b.size = Vector2(103, 52)
        b.add_theme_font_size_override("font_size", 26)
        add_child(b)
    speed_one.position = Vector2(1688, 16)
    speed_two.position = Vector2(1791, 16)
    speed_one.toggle_mode = true
    speed_two.toggle_mode = true
    speed_one.pressed.connect(func() -> void: _set_speed(1))
    speed_two.pressed.connect(func() -> void: _set_speed(2))

    battle_button = UI.make_button("전투 시작")
    battle_button.custom_minimum_size = Vector2.ZERO
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
    camera_target = Vector2.ZERO
    camera_offset = Vector2.ZERO
    battle_seconds = 0.0
    log_items = ["%d주차 전투 준비 중입니다." % week]


func _find_node(id: String) -> Dictionary:
    for item in NODES:
        if str(item["id"]) == id:
            return item
    return {}


func _node_screen(node: Dictionary) -> Vector2:
    return Vector2(0, 84) + node["p"] + camera_offset


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


func _select_node(id: String) -> void:
    if _find_node(id).is_empty():
        return
    selected_id = id
    var node := _find_node(id)
    camera_target = Vector2(688, 446) - node["p"]
    _update_popup()
    queue_redraw()


func _update_popup() -> void:
    if selected_id.is_empty():
        deploy_button.visible = false
        return
    var node := _find_node(selected_id)
    if node.is_empty():
        deploy_button.visible = false
        return
    var p := _node_screen(node)
    var panel_x: float = clampf(p.x + 100, 28, 1376 - 390 - 28)
    var panel_y: float = clampf(p.y - 112, 104, 480 if phase == "dialogue" else 670)
    deploy_button.position = Vector2(panel_x + 205, panel_y + 194)
    deploy_button.visible = str(node["kind"]) == "unit"
    deploy_button.disabled = int(node["week"]) > week or phase == "battle" or phase == "result"
    deploy_button.text = "배치" if not deploy_button.disabled else "배치 불가"


func _process(delta: float) -> void:
    if camera_offset.distance_squared_to(camera_target) > 0.5:
        camera_offset = camera_offset.lerp(camera_target, minf(1.0, delta * 9.0))
        _update_popup()
        queue_redraw()
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
            queue_redraw()


func _input(event: InputEvent) -> void:
    if phase != "dialogue" or not (event is InputEventKey):
        return
    var key_event := event as InputEventKey
    if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
        _advance_dialogue()
        get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var mouse := (event as InputEventMouseMotion).position
        var found := ""
        if mouse.x < 1376 and mouse.y >= 84 and mouse.y < 976:
            for node in NODES:
                if _node_screen(node).distance_to(mouse) <= 48.0:
                    found = str(node["id"])
                    break
        if found != hover_id:
            hover_id = found
            queue_redraw()
    elif event is InputEventMouseButton:
        var click := event as InputEventMouseButton
        if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
            return
        if phase == "dialogue" and Rect2(28, 778, 1320, 171).has_point(click.position):
            _advance_dialogue()
            return
        if click.position.x < 1376 and click.position.y > 84 and click.position.y < 976:
            for node in NODES:
                if _node_screen(node).distance_to(click.position) <= 49.0:
                    _select_node(str(node["id"]))
                    return
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
    queue_redraw()


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
    queue_redraw()


func _text(value: String, p: Vector2, font_size: int, color: Color = UI.TEXT) -> void:
    draw_string(FONT, p + Vector2(0, font_size), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _box(rect: Rect2, fill: Color, border: Color = UI.BORDER) -> void:
    draw_rect(rect, fill)
    draw_rect(rect, border, false, 2.0)


func _draw() -> void:
    # Fixed 1920×1080 logical canvas, shared with every menu screen.
    draw_rect(Rect2(0, 0, 1920, 1080), UI.BACKGROUND)
    _box(Rect2(0, 0, 1376, 84), UI.HEADER)
    _box(Rect2(1376, 0, 544, 84), UI.HEADER)
    _box(Rect2(0, 84, 1376, 892), UI.GAME_BACKGROUND)
    _box(Rect2(0, 976, 1376, 104), UI.PANEL)
    _box(Rect2(1376, 84, 544, 652), UI.GAME_BACKGROUND)
    _box(Rect2(1376, 736, 544, 240), UI.PANEL)
    _box(Rect2(1376, 976, 544, 104), UI.PANEL)
    for x in range(0, 1376, 56):
        draw_line(Vector2(x, 84), Vector2(x, 976), UI.GRID, 1.0)
    for y in range(84, 976, 56):
        draw_line(Vector2(0, y), Vector2(1376, y), UI.GRID, 1.0)
    _text("%02d주차" % week, Vector2(44, 16), 38)
    draw_line(Vector2(233, 17), Vector2(233, 67), UI.BORDER, 2)
    _text("%s G" % _group_digits(g), Vector2(271, 17), 37, UI.GOLD)
    var secs := int(battle_seconds)
    _text("%02d:%02d" % [secs / 60, secs % 60], Vector2(1410, 16), 36)
    _draw_tree()
    _draw_field()
    _text("전투 정보", Vector2(1400, 747), 28)
    draw_line(Vector2(1400, 790), Vector2(1896, 790), UI.BORDER, 2)
    _text("도움말", Vector2(115, 992), 23, UI.GOLD)
    _text(_help_text(), Vector2(240, 992), 25)
    if phase == "dialogue":
        _draw_dialogue()


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
    var path := _selected_ancestors()
    for node in NODES:
        var parent_id := str(node["parent"])
        if parent_id.is_empty():
            continue
        var parent := _find_node(parent_id)
        var a := _node_screen(parent)
        var b := _node_screen(node)
        var middle_y := (a.y + b.y) * 0.5
        var highlight := str(node["id"]) in path and parent_id in path
        var tint := UI.TEAL if highlight else UI.TREE_LINE
        draw_polyline(PackedVector2Array([a - Vector2(0, 35), Vector2(a.x, middle_y),
            Vector2(b.x, middle_y), b + Vector2(0, 35)]), tint, 5.0 if highlight else 3.5, true)
    for node in NODES:
        var p := _node_screen(node)
        if p.y < 84 or p.y > 976 or p.x < 0 or p.x > 1376:
            continue
        var id := str(node["id"])
        var locked := int(node["week"]) > week
        var focused := id == selected_id
        var hovered := id == hover_id
        var radius := 38.0 * (1.12 if focused or hovered else 1.0)
        var kind := str(node["kind"])
        var fill := UI.LOCKED if locked else UI.NODE_FILL
        var border := UI.TREE_LINE if locked else (UI.GOLD if focused else UI.TEAL)
        if kind == "branch":
            draw_rect(Rect2(p - Vector2.ONE * radius * 0.75, Vector2.ONE * radius * 1.5), fill)
            draw_rect(Rect2(p - Vector2.ONE * radius * 0.75, Vector2.ONE * radius * 1.5), border, false, 3.0)
        elif kind == "root":
            draw_colored_polygon(PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius,0),
                p+Vector2(0,radius),p+Vector2(-radius,0)]), fill)
        else:
            draw_circle(p, radius, fill)
            draw_arc(p, radius, 0.0, TAU, 48, border, 4.0, true)
        var symbol: String = str(node["symbol"])
        _text(symbol, p + Vector2(-13, -22), 31, border)
        _text(str(node["name"]), p + Vector2(-40, radius + 7), 22, UI.MUTED if locked else UI.TEXT)
    _draw_popup()


func _draw_popup() -> void:
    if selected_id.is_empty():
        return
    var node := _find_node(selected_id)
    if node.is_empty():
        return
    var p := _node_screen(node)
    var x: float = clampf(p.x + 100, 28, 1376 - 390 - 28)
    var y: float = clampf(p.y - 112, 104, 706 if phase == "dialogue" else 670)
    _box(Rect2(x, y, 390, 274), UI.PANEL, UI.TEAL)
    _text(str(node["name"]), Vector2(x + 25, y + 20), 32)
    var details := str(node["detail"]).split("|")
    for i in range(details.size()):
        _text(str(details[i]), Vector2(x + 25, y + 75 + i * 37), 25, UI.MUTED)


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


func _draw_dialogue() -> void:
    var area := Rect2(28, 778, 1320, 171)
    _box(area, UI.DIALOGUE_PANEL, UI.GOLD)
    _box(Rect2(52, 800, 112, 125), UI.NODE_FILL, UI.GOLD)
    var speaker := "해설" if dialogue_index == 0 or dialogue_index == 2 or dialogue_index == 4 else "작전 참모"
    _text("≋" if speaker == "해설" else "◆", Vector2(83, 815), 48, UI.GOLD)
    _text(speaker, Vector2(196, 793), 26, UI.GOLD)
    var text_lines := _dialogue_content()
    _text(text_lines[min(dialogue_index, DIALOGUE_COUNT - 1)], Vector2(196, 845), 28)
    _text("Space  다음 ›", Vector2(1137, 905), 21, UI.MUTED)

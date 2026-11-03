extends SceneTree
## Headless scene smoke test. This validates state/interaction wiring, not combat balance or visual QA.

func _initialize() -> void:
    call_deferred("_run")

func _mouse_button(pressed: bool, at: Vector2) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.position = at
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = pressed
    return event


func _mouse_motion(at: Vector2) -> InputEventMouseMotion:
    var event := InputEventMouseMotion.new()
    event.position = at
    return event


const UI = preload("res://scripts/ui_style.gd")
const TREE_NODE_IDS := ["root", "command", "guard", "scout", "mobility", "supply", "drone", "elite"]


func _has_readable_node(game: Control, camera: Vector2) -> bool:
    # Independent validation: an entire icon+name footprint must fit inside
    # the unobscured part of the tree panel; a line/sliver is insufficient.
    var visible: Rect2 = game.call("_readable_tree_area")
    for id in TREE_NODE_IDS:
        var node: Dictionary = game.call("_find_node", id)
        var bounds: Rect2 = game.call("_node_visual_rect", node)
        var on_screen := Rect2(bounds.position + camera, bounds.size)
        if visible.encloses(on_screen):
            return true
    return false


func _assert_readable_tree(game: Control) -> bool:
    var offset: Vector2 = game.get("camera_offset")
    if not _has_readable_node(game, offset):
        push_error("W52 smoke: no complete node+label visible at camera %s" % str(offset))
        return false
    return true


func _check_pixel_layout(game: Control) -> bool:
    var expected := {
        "L1": Rect2i(4, 40, 441, 42),
        "L2": Rect2i(4, 89, 441, 219),
        "L3": Rect2i(4, 315, 441, 42),
        "R1": Rect2i(452, 40, 185, 42),
        "R2": Rect2i(452, 89, 185, 155),
        "R3": Rect2i(452, 251, 185, 57),
        "R4": Rect2i(452, 315, 185, 42)
    }
    if UI.PANEL_IDS.size() != 7 or UI.SCREW_DIAMETER != 3 or UI.FRAME_THICKNESS != 7:
        push_error("W52 smoke: wrong seven-panel metal hardware contract")
        return false
    var screws := 0
    for id in UI.PANEL_IDS:
        var frame: Rect2i = UI.frame_rect(id)
        if frame != expected[id]:
            push_error("W52 smoke: bad %s frame %s" % [id, frame])
            return false
        var origins: Array[Vector2i] = UI.screw_origins(id)
        if origins.size() != 4:
            push_error("W52 smoke: missing corner screws")
            return false
        var corners := [
            frame.position + Vector2i(5, 5),
            Vector2i(frame.end.x - 8, frame.position.y + 5),
            Vector2i(frame.position.x + 5, frame.end.y - 8),
            frame.end - Vector2i(8, 8)
        ]
        for i in range(4):
            if origins[i] != corners[i]:
                push_error("W52 smoke: uncentered 3px corner screw")
                return false
        screws += origins.size()
    if screws != 28:
        push_error("W52 smoke: expected 28 screws")
        return false
    if UI.boundary(0) != 36 or UI.boundary(3) != 85 or UI.boundary(13) != 247 \
            or UI.boundary(17) != 311 or UI.boundary(20) != 360:
        push_error("W52 smoke: inconsistent snapped shared boundaries")
        return false
    if UI.content_rect("L2") != Rect2i(11, 96, 427, 205):
        push_error("W52 smoke: tree interior not inset by 7 pixels")
        return false
    if Rect2(UI.DIALOGUE_RECT) != Rect2(4, 251, 426, 43) \
            or game.get("DIALOGUE_RECT") != Rect2(UI.DIALOGUE_RECT):
        push_error("W52 smoke: floating dialogue is not aligned with R3")
        return false
    if UI.frame_rect("L1").end.y != UI.frame_rect("R1").end.y \
            or UI.frame_rect("L3").position.y != UI.frame_rect("R4").position.y:
        push_error("W52 smoke: left/right frame misalignment")
        return false
    var allowed := ["000000", "323c39", "222034", "595652", "696a6a", "eec39a",
        "9badb7", "d9a066", "37946e", "847e87", "8a6f30", "8f563b", "663931"]
    for token in [UI.BACKGROUND, UI.PANEL, UI.BORDER, UI.PRIMARY, UI.PRIMARY_HOVER,
            UI.TEXT, UI.MUTED, UI.GAME_BACKGROUND, UI.HEADER, UI.GRID, UI.GRID_BORDER,
            UI.TREE_LINE, UI.NODE_FILL, UI.LOCKED, UI.GOLD, UI.TEAL, UI.ENEMY,
            UI.ENEMY_CELL, UI.ALLY_CELL, UI.DIALOGUE_PANEL, UI.METAL_LIGHT,
            UI.METAL_MID, UI.METAL_DARK, UI.EDGE_DARK, UI.BUTTON_SHADE,
            UI.BUTTON_EDGE, UI.BUTTON_DARK]:
        if not token.to_html(false) in allowed:
            push_error("W52 smoke: palette token outside allowed DB32 colors")
            return false
    if ProjectSettings.get_setting("display/window/stretch/mode") != "viewport" \
            or ProjectSettings.get_setting("display/window/stretch/aspect") != "keep" \
            or ProjectSettings.get_setting("display/window/stretch/scale_mode") != "integer" \
            or int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) != 0:
        push_error("W52 smoke: pixel scaling/texture filtering contract incorrect")
        return false
    return true


func _check_tree_pan_and_popup(game: Control) -> bool:
    # The tree must be a child canvas of a bounded clipping Control.
    var clip := game.get_node_or_null("TreeClip") as Control
    if clip == null or not clip.clip_contents:
        push_error("W52 smoke: missing clipped tree viewport")
        return false
    if clip.position != Vector2(11, 96) or clip.size != Vector2(427, 205):
        push_error("W52 smoke: clipped tree bounds incorrect")
        return false
    var art := clip.get_node_or_null("TreeArt") as Control
    if art == null or art.get_parent() != clip or art.size != clip.size:
        push_error("W52 smoke: tree artwork must be a child of clip boundary")
        return false
    if art.mouse_filter != Control.MOUSE_FILTER_IGNORE or clip.mouse_filter != Control.MOUSE_FILTER_IGNORE:
        push_error("W52 smoke: clipped tree intercepts mouse input")
        return false
    # Dialogue and popup render independently above the clipped artwork.
    if game.get_node_or_null("NodeInfoLayer") == null or game.get_node_or_null("DialogueLayer") == null:
        push_error("W52 smoke: popup/dialogue overlay layer missing")
        return false
    # The same popup rectangle must position its painted panel and actual Button.
    game.call("_select_node", "guard")
    game.call("_process", 1.0)
    # Selected unit remains centered; other branches can extend offscreen.
    var guard: Dictionary = game.call("_find_node", "guard")
    var focus_offset: Vector2 = game.get("camera_offset")
    var expected_focus: Vector2 = game.call("_clamp_pan", Vector2(213, 102) - Vector2(guard["p"]) * 0.25)
    if focus_offset.distance_to(expected_focus) > 0.1:
        push_error("W52 smoke: guard focus not at readable camera target")
        return false
    if not _assert_readable_tree(game):
        return false
    # The dialogue overlays the lower tree; it must not conceal the only
    # remaining recognizable node when the camera is pushed to a corner.
    for extreme in [Vector2(90000, 90000), Vector2(-90000, -90000),
                    Vector2(90000, -90000), Vector2(-90000, 90000)]:
        var camera_during_dialogue: Vector2 = game.call("_clamp_pan", extreme)
        if not _has_readable_node(game, camera_during_dialogue):
            push_error("W52 smoke: dialogue covered all identifiable nodes at drag limit")
            return false
    var popup: Rect2 = game.call("_popup_rect")
    var deploy: Button = game.get("deploy_button")
    if deploy.size != Vector2(61, 31) or deploy.custom_minimum_size != Vector2(61, 31):
        push_error("W52 smoke: deploy dimensions actual=%s min=%s expected=(61, 31)" % [str(deploy.size), str(deploy.custom_minimum_size)])
        return false
    var prev: Button = game.get("prev_button")
    var next_help: Button = game.get("next_button")
    if prev.size != Vector2(25, 26) or next_help.size != Vector2(25, 26):
        push_error("W52 smoke: help arrows size invalid: prev=%s next=%s" % [str(prev.size), str(next_help.size)])
        return false
    if not popup.encloses(Rect2(deploy.position, deploy.size)):
        push_error("W52 smoke: deploy button outside popup during dialogue: panel=%s btn=%s size=%s" % [str(popup), str(deploy.position), str(deploy.size)])
        return false
    if popup.end.y > 251.0:
        push_error("W52 smoke: popup collides with dialogue")
        return false
    # The popup surface cannot arm the background pan.
    game.call("_gui_input", _mouse_button(true, popup.position + Vector2(28, 28)))
    if bool(game.get("pan_armed")):
        push_error("W52 smoke: popup click started tree pan")
        return false
    game.call("_set_week_intro")
    game.call("_refresh_all")
    for i in range(5):
        game.call("_advance_dialogue")
    game.call("_select_node", "guard")
    game.call("_process", 1.0)
    popup = game.call("_popup_rect")
    if not popup.encloses(Rect2(deploy.position, deploy.size)):
        push_error("W52 smoke: deploy button outside popup after dialogue: panel=%s btn=%s size=%s" % [str(popup), str(deploy.position), str(deploy.size)])
        return false
    # Drag from background; release must not change selection.
    var start := Vector2(90, 190)
    var before: Vector2 = game.get("camera_offset")
    game.call("_gui_input", _mouse_button(true, start))
    game.call("_input", _mouse_motion(start + Vector2(1, 1)))
    var under_threshold: Vector2 = game.get("camera_offset")
    if under_threshold.distance_to(before) > 0.1:
        push_error("W52 smoke: under-threshold motion panned tree")
        return false
    game.call("_input", _mouse_motion(start + Vector2(96, 82)))
    var moved: Vector2 = game.get("camera_offset")
    if not _assert_readable_tree(game):
        return false
    if moved.distance_to(before) < 10:
        push_error("W52 smoke: background drag did not pan tree")
        return false
    game.call("_input", _mouse_button(false, start + Vector2(96, 82)))
    if bool(game.get("pan_armed")) or str(game.get("selected_id")) != "guard":
        push_error("W52 smoke: releasing drag did not end pan cleanly")
        return false
    # Large drags in all four diagonal directions may clip most of the tree,
    # but must leave at least one complete node+label, even across sparse gaps.
    var extreme_positions := [
        Vector2(9000, 9000), Vector2(-9000, -9000),
        Vector2(9000, -9000), Vector2(-9000, 9000)
    ]
    for extreme in extreme_positions:
        game.call("_gui_input", _mouse_button(true, start))
        game.call("_input", _mouse_motion(extreme))
        var camera_at_end: Vector2 = game.get("camera_offset")
        game.call("_input", _mouse_button(false, extreme))
        if not _assert_readable_tree(game):
            return false
        var projected: Vector2 = game.call("_clamp_pan", camera_at_end)
        if camera_at_end.distance_to(projected) > 0.1:
            push_error("W52 smoke: extreme pan escaped readable-node region")
            return false
        if bool(game.get("pan_armed")):
            push_error("W52 smoke: extreme pan did not release")
            return false
    # No fixed-size padding: the extreme pan may place all but one node offscreen.
    var huge: Vector2 = game.call("_clamp_pan", Vector2(90000, 90000))
    if not _has_readable_node(game, huge):
        push_error("W52 smoke: giant positive pan lost all recognizable content")
        return false
    var far: Vector2 = game.call("_clamp_pan", Vector2(-90000, -90000))
    if not _has_readable_node(game, far):
        push_error("W52 smoke: giant negative pan lost all recognizable content")
        return false
    # Sample many arbitrary pan targets, not only screen corners.
    # Reprojecting any valid position must not move the camera again.
    for gx in range(-3, 4):
        for gy in range(-3, 4):
            var requested := Vector2(gx * 1400, gy * 1000)
            var clamped: Vector2 = game.call("_clamp_pan", requested)
            if not _has_readable_node(game, clamped):
                push_error("W52 smoke: arbitrary pan obscured every complete node")
                return false
            var again: Vector2 = game.call("_clamp_pan", clamped)
            if again.distance_to(clamped) > 0.1:
                push_error("W52 smoke: readable camera region unstable under reprojection")
                return false
    # Every skill node, including extremes of a large branching tree, can
    # focus to the center without losing all identifiable on-screen content.
    for node_id in TREE_NODE_IDS:
        game.call("_select_node", node_id)
        for frame in range(12):
            game.call("_process", 0.016)
            if not _assert_readable_tree(game):
                push_error("W52 smoke: focus animation crossed an empty tree view")
                return false
        game.call("_process", 1.0)
        var chosen: Dictionary = game.call("_find_node", node_id)
        var chosen_screen: Vector2 = game.call("_node_screen", chosen)
        if chosen_screen.distance_to(Vector2(224, 198)) > 0.1:
            push_error("W52 smoke: node %s did not focus exactly at tree center" % node_id)
            return false
        if not _assert_readable_tree(game):
            return false
    # Edge node focus may clip distant branches, but keeps the selected node centered.
    game.call("_select_node", "mobility")
    game.call("_process", 1.0)
    var mobility: Dictionary = game.call("_find_node", "mobility")
    expected_focus = game.call("_clamp_pan", Vector2(213, 102) - Vector2(mobility["p"]) * 0.25)
    focus_offset = game.get("camera_offset")
    if focus_offset.distance_to(expected_focus) > 0.1:
        push_error("W52 smoke: edge focus did not honor camera range")
        return false
    if not _assert_readable_tree(game):
        return false
    # A focused center node remains centered even when branches are clipped.
    game.call("_select_node", "root")
    game.call("_process", 1.0)
    var root_node: Dictionary = game.call("_find_node", "root")
    var root_screen: Vector2 = game.call("_node_screen", root_node)
    if root_screen.distance_to(Vector2(224, 198)) > 0.1:
        push_error("W52 smoke: central focus not centered")
        return false
    if not _assert_readable_tree(game):
        return false
    # A short click on a visible node still selects it; dragging that node does not.
    var command_pos: Vector2 = game.call("_node_screen", game.call("_find_node", "command"))
    game.call("_gui_input", _mouse_button(true, command_pos))
    game.call("_input", _mouse_motion(command_pos + Vector2(1, 0)))
    game.call("_input", _mouse_button(false, command_pos + Vector2(3, 0)))
    if str(game.get("selected_id")) != "command":
        push_error("W52 smoke: short node click failed after panning")
        return false
    var scout_pos: Vector2 = game.call("_node_screen", game.call("_find_node", "scout"))
    game.call("_gui_input", _mouse_button(true, scout_pos))
    game.call("_input", _mouse_motion(scout_pos + Vector2(-45, -22)))
    game.call("_input", _mouse_button(false, scout_pos + Vector2(-45, -22)))
    if str(game.get("selected_id")) != "command":
        push_error("W52 smoke: dragging a node unexpectedly changed selection")
        return false
    game.call("_set_week_intro")
    game.call("_refresh_all")
    return true


func _run() -> void:
    var game_scene: PackedScene = load("res://scenes/game.tscn")
    if game_scene == null:
        push_error("W52 smoke: missing Game scene")
        quit(1)
        return
    var game: Control = game_scene.instantiate() as Control
    # Standalone Game needs the same parent Theme as Main._ready() uses;
    # otherwise engine fallback font 16px falsely inflates button hit targets.
    var font := load("res://assets/fonts/ui_ko_subset.woff2") as Font
    var fallback_fonts: Array[Font] = []
    for part in [19, 96, 98, 101, 103, 105, 106, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]:
        var part_font := load("res://assets/fonts/nanum-%d.woff2" % part) as Font
        if part_font != null:
            fallback_fonts.append(part_font)
    font.set_fallbacks(fallback_fonts)
    var ui_theme := Theme.new()
    ui_theme.default_font = font
    ui_theme.default_font_size = 12
    game.theme = ui_theme
    root.add_child(game)
    await process_frame

    if int(ProjectSettings.get_setting("display/window/size/viewport_width")) != 640:
        push_error("W52 smoke: wrong logical viewport width")
        quit(1)
        return
    if int(ProjectSettings.get_setting("display/window/size/viewport_height")) != 360:
        push_error("W52 smoke: wrong logical viewport height")
        quit(1)
        return

    if not _check_pixel_layout(game) or not _assert_readable_tree(game) or not _check_tree_pan_and_popup(game):
        quit(1)
        return

    var battles := 0
    for expected_week in range(1, 53):
        if int(game.get("week")) != expected_week:
            push_error("W52 smoke: week mismatch at %d" % expected_week)
            quit(1)
            return
        for line in range(5):
            game.call("_advance_dialogue")
        if str(game.get("phase")) != "prepare":
            push_error("W52 smoke: dialogue did not enter prepare")
            quit(1)
            return

        game.call("_change_help", 999)
        if int(game.get("help_index")) > expected_week:
            push_error("W52 smoke: future help unlocked")
            quit(1)
            return

        game.call("_select_node", "guard")
        if str(game.get("selected_id")) != "guard":
            push_error("W52 smoke: tree node selection failed")
            quit(1)
            return
        game.call("_deploy_selected")
        var allies: Array = game.get("placements")
        if allies.is_empty():
            push_error("W52 smoke: deploy failed")
            quit(1)
            return
        var expected_grid := Vector2i(6, 6) if expected_week <= 13 else (
            Vector2i(8, 8) if expected_week <= 26 else (
                Vector2i(10, 8) if expected_week <= 39 else Vector2i(10, 10)))
        var actual_grid: Vector2i = game.call("_grid_size")
        if actual_grid != expected_grid:
            push_error("W52 smoke: week-based battlefield grid changed")
            quit(1)
            return
        var geometry: Dictionary = game.call("_grid_geometry")
        var field: Rect2 = Rect2(UI.content_rect("R2"))
        var grid_top_left: Vector2 = Vector2(geometry["start"])
        var cell_width: float = float(geometry["cell"])
        if not field.encloses(Rect2(grid_top_left, Vector2(actual_grid) * cell_width)):
            push_error("W52 smoke: battlefield grid escaped its frame")
            quit(1)
            return
        game.set("selected_id", "")
        var ally_click := grid_top_left + Vector2(cell_width * 1.5,
            cell_width * (float(actual_grid.y) - 0.5))
        game.call("_gui_input", _mouse_button(true, ally_click))
        if str(game.get("selected_id")) != "guard":
            push_error("W52 smoke: field cell click did not select corresponding tree unit")
            quit(1)
            return

        game.call("_battle_action")
        if str(game.get("phase")) != "battle":
            push_error("W52 smoke: failed to start battle")
            quit(1)
            return
        game.call("_battle_action")
        if str(game.get("phase")) != "battle":
            push_error("W52 smoke: duplicate start corrupted phase")
            quit(1)
            return
        game.call("_process", 19.0)
        if str(game.get("phase")) != "result":
            push_error("W52 smoke: result transition failed")
            quit(1)
            return
        battles += 1
        if expected_week < 52:
            game.call("_battle_action")

    if battles != 52 or int(game.get("week")) != 52:
        push_error("W52 smoke: expected 52 battles")
        quit(1)
        return

    var store = load("res://scripts/save_manager.gd").new()
    # Removed movement-demo save format must not be loaded as W52 progress.
    var legacy_save := ConfigFile.new()
    legacy_save.set_value("session", "version", 1)
    legacy_save.set_value("session", "x", 480.0)
    legacy_save.set_value("session", "y", 270.0)
    if legacy_save.save("user://game_save.cfg") != OK:
        push_error("W52 smoke: could not create legacy-format fixture")
        quit(1)
        return
    if not store.load_game().is_empty():
        push_error("W52 smoke: legacy movement-demo save was incorrectly accepted")
        quit(1)
        return
    var saved: Dictionary = game.call("snapshot")
    if not store.save_game(saved):
        push_error("W52 smoke: save failed")
        quit(1)
        return
    var restored: Dictionary = store.load_game()
    if int(restored.get("week", 0)) != 52 or int(restored.get("g", -1)) < 0:
        push_error("W52 smoke: restore invalid")
        quit(1)
        return
    store.clear_save()
    print("W52_UI_SMOKE_OK: 52 battles, dialogues, help gating, deployment, save/restore, 640x360 integer viewport")
    quit(0)

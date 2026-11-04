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


const TREE_NODE_IDS := ["hq","robot_factory","walker_factory","radar","reactor","armory","machine_shop","drone_hangar","rifle","mg","mortar","anti_tank","artillery","car","tank","destroyer","heavy","fighter","attacker","bomber"]


func _has_readable_node(game: Control, camera: Vector2) -> bool:
    # Independent validation: an entire icon+name footprint must fit inside
    # the unobscured part of the tree panel; a line/sliver is insufficient.
    var visible: Rect2 = game.call("_readable_tree_area")
    for id in TREE_NODE_IDS:
        var node: Dictionary = game.call("_find_node", id)
        if not game.call("_node_visible", node):
            continue
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


func _check_tree_pan_and_popup(game: Control) -> bool:
    game.set("full_tree_view", true)
    # The tree must be a child canvas of a bounded clipping Control.
    var clip := game.get_node_or_null("TreeClip") as Control
    if clip == null or not clip.clip_contents:
        push_error("W52 smoke: missing clipped tree viewport")
        return false
    if clip.position != Vector2(0, 84) or clip.size != Vector2(1376, 892):
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
    game.call("_select_node", "rifle")
    game.call("_process", 1.0)
    # Selected unit remains centered; other branches can extend offscreen.
    var guard: Dictionary = game.call("_find_node", "rifle")
    var focus_offset: Vector2 = game.get("camera_offset")
    var expected_focus: Vector2 = game.call("_clamp_pan", Vector2(688, 446) - guard["p"])
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
    if deploy.size != Vector2(160, 62) or deploy.custom_minimum_size != Vector2(160, 62):
        push_error("W52 smoke: deploy control inherited menu button dimensions")
        return false
    var speed_one: Button = game.get("speed_one")
    var speed_two: Button = game.get("speed_two")
    var prev: Button = game.get("prev_button")
    var next_help: Button = game.get("next_button")
    if speed_one.size != Vector2(103, 52) or speed_two.size != Vector2(103, 52):
        push_error("W52 smoke: speed control size invalid")
        return false
    if prev.size != Vector2(72, 64) or next_help.size != Vector2(72, 64):
        push_error("W52 smoke: help arrows size invalid")
        return false
    if not popup.encloses(Rect2(deploy.position, deploy.size)):
        push_error("W52 smoke: deploy button outside popup during dialogue: panel=%s btn=%s size=%s" % [str(popup), str(deploy.position), str(deploy.size)])
        return false
    var upgrades: Rect2 = game.call("_upgrade_rect")
    if upgrades.size != Vector2(420, 256) or upgrades.intersects(popup) or upgrades.position.x < 0.0 or upgrades.end.x > 1376.0 or upgrades.end.y > 778.0:
        push_error("W52 tech: independent upgrade panel is clipped or overlaps a blocking UI region")
        return false
    if popup.end.y > 754.0:
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
    game.call("_select_node", "rifle")
    game.call("_process", 1.0)
    popup = game.call("_popup_rect")
    if not popup.encloses(Rect2(deploy.position, deploy.size)):
        push_error("W52 smoke: deploy button outside popup after dialogue: panel=%s btn=%s size=%s" % [str(popup), str(deploy.position), str(deploy.size)])
        return false
    # Drag from background; release must not change selection.
    var start := Vector2(90, 190)
    var before: Vector2 = game.get("camera_offset")
    game.call("_gui_input", _mouse_button(true, start))
    game.call("_input", _mouse_motion(start + Vector2(3, 2)))
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
    if bool(game.get("pan_armed")) or str(game.get("selected_id")) != "rifle":
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
        if chosen_screen.distance_to(Vector2(688, 530)) > 0.1:
            push_error("W52 smoke: node %s did not focus exactly at tree center" % node_id)
            return false
        if not _assert_readable_tree(game):
            return false
    # Edge node focus may clip distant branches, but keeps the selected node centered.
    game.call("_select_node", "bomber")
    game.call("_process", 1.0)
    var mobility: Dictionary = game.call("_find_node", "bomber")
    expected_focus = game.call("_clamp_pan", Vector2(688, 446) - mobility["p"])
    focus_offset = game.get("camera_offset")
    if focus_offset.distance_to(expected_focus) > 0.1:
        push_error("W52 smoke: edge focus did not honor camera range")
        return false
    if not _assert_readable_tree(game):
        return false
    # A focused center node remains centered even when branches are clipped.
    game.call("_select_node", "hq")
    game.call("_process", 1.0)
    var root_node: Dictionary = game.call("_find_node", "hq")
    var root_screen: Vector2 = game.call("_node_screen", root_node)
    if root_screen.distance_to(Vector2(688, 530)) > 0.1:
        push_error("W52 smoke: central focus not centered")
        return false
    if not _assert_readable_tree(game):
        return false
    # A short click on a visible node still selects it; dragging that node does not.
    var command_pos: Vector2 = game.call("_node_screen", game.call("_find_node", "robot_factory"))
    game.call("_gui_input", _mouse_button(true, command_pos))
    game.call("_input", _mouse_motion(command_pos + Vector2(3, 0)))
    game.call("_input", _mouse_button(false, command_pos + Vector2(3, 0)))
    if str(game.get("selected_id")) != "robot_factory":
        push_error("W52 smoke: short node click failed after panning")
        return false
    var scout_pos: Vector2 = game.call("_node_screen", game.call("_find_node", "armory"))
    game.call("_gui_input", _mouse_button(true, scout_pos))
    game.call("_input", _mouse_motion(scout_pos + Vector2(-45, -22)))
    game.call("_input", _mouse_button(false, scout_pos + Vector2(-45, -22)))
    if str(game.get("selected_id")) != "robot_factory":
        push_error("W52 smoke: dragging a node unexpectedly changed selection")
        return false
    game.call("_set_week_intro")
    game.call("_refresh_all")
    return true


func _check_integrated_tree(game: Control) -> bool:
    var constants: Dictionary = game.get_script().get_script_constant_map()
    var nodes: Array = constants.get("NODES", [])
    var upgrades: Dictionary = constants.get("UPGRADES", {})
    if nodes.size() != 20 or upgrades.size() != 12:
        push_error("W52 tech: expected 20 nodes and 12 unit upgrade sets")
        return false
    var seen: Dictionary = {}
    var counts := {"root":0, "production":0, "tech":0, "unit":0}
    var parents: int = 0
    for node in nodes:
        var id: String = str(node["id"])
        var kind: String = str(node["kind"])
        if seen.has(id) or not counts.has(kind):
            push_error("W52 tech: duplicate or unknown node")
            return false
        seen[id] = true
        counts[kind] += 1
        if str(node["parent"]) != "":
            parents += 1
        if kind == "unit":
            if not upgrades.has(id) or (upgrades[id] as Array).size() != 2:
                push_error("W52 tech: missing A/B for " + id)
                return false
            for req in node["requires"]:
                var building: Dictionary = game.call("_find_node", str(req))
                if building.is_empty() or str(building["kind"]) == "unit":
                    push_error("W52 tech: invalid building prerequisite")
                    return false
    if counts != {"root":1, "production":3, "tech":4, "unit":12} or parents != 19:
        push_error("W52 tech: node shapes or parent count mismatch")
        return false
    for node in nodes:
        var parent := str(node["parent"])
        if parent != "" and not seen.has(parent):
            push_error("W52 tech: missing parent " + parent)
            return false
    var owned: Array = game.get("owned_buildings")
    if owned.size() != 2 or "hq" not in owned or "robot_factory" not in owned:
        push_error("W52 tech: incorrect initial buildings")
        return false
    if bool(game.get("full_tree_view")):
        push_error("W52 tech: default view must preview only the next step")
        return false
    # Verify the first visible frame shows the new HQ above the dialogue mask.
    var hq: Dictionary = game.call("_find_node", "hq")
    var hq_bounds: Rect2 = game.call("_node_visual_rect", hq)
    var viewport: Rect2 = game.call("_readable_tree_area")
    var hq_camera: Vector2 = game.get("camera_offset")
    if not viewport.encloses(Rect2(hq_bounds.position + hq_camera, hq_bounds.size)):
        push_error("W52 tech: HQ is hidden by dialogue on the initial camera")
        return false
    for node in nodes:
        var node_id: String = str(node["id"])
        var parent_id: String = str(node["parent"])
        var expected_visible: bool = node_id in owned or parent_id in owned
        if bool(game.call("_node_visible", node)) != expected_visible:
            push_error("W52 tech: default one-level reveal differs for %s" % node_id)
            return false
    var fighter: Dictionary = game.call("_find_node", "fighter")
    if game.call("_node_visible", fighter):
        push_error("W52 tech: hidden child revealed before hangar")
        return false
    var view_button: Button = game.get("full_view_button") as Button
    if view_button == null or view_button.text != "전체 기술도":
        push_error("W52 tech: missing discoverable full-tree button")
        return false
    view_button.emit_signal("pressed")
    if not bool(game.get("full_tree_view")) or view_button.text != "기본 트리":
        push_error("W52 tech: full-tree button did not enter overview mode")
        return false
    for node in nodes:
        if not game.call("_node_visible", node):
            push_error("W52 tech: full tree did not reveal every node")
            return false
    view_button.emit_signal("pressed")
    if bool(game.get("full_tree_view")) or view_button.text != "전체 기술도":
        push_error("W52 tech: full-tree button did not return to default")
        return false
    var g_before: int = game.get("g")
    game.call("_select_node", "walker_factory")
    game.call("_build_selected")
    if "walker_factory" in game.get("owned_buildings"):
        push_error("W52 tech: walker factory built before W09")
        return false
    game.set("week", 9)
    game.call("_build_selected")
    if "walker_factory" not in game.get("owned_buildings"):
        push_error("W52 tech: walker factory did not build instantly at W09")
        return false
    game.set("week", 18)
    game.call("_select_node", "machine_shop")
    game.call("_build_selected")
    if "machine_shop" not in game.get("owned_buildings"):
        push_error("W52 tech: machine shop requirement failed")
        return false
    var tank: Dictionary = game.call("_find_node", "tank")
    if not game.call("_is_node_unlocked", tank):
        push_error("W52 tech: tank not unlocked by machine shop")
        return false
    game.set("week", 21)
    var artillery: Dictionary = game.call("_find_node", "artillery")
    if game.call("_is_node_unlocked", artillery):
        push_error("W52 tech: artillery bypassed shared facilities")
        return false
    game.call("_select_node", "armory")
    game.call("_build_selected")
    if game.call("_is_node_unlocked", artillery):
        push_error("W52 tech: artillery bypassed radar requirement")
        return false
    game.call("_select_node", "radar")
    game.call("_build_selected")
    if not game.call("_is_node_unlocked", artillery):
        push_error("W52 tech: artillery remained locked after armory + radar")
        return false
    game.set("week", 40)
    game.call("_select_node", "drone_hangar")
    game.call("_build_selected")
    game.call("_select_node", "reactor")
    game.call("_build_selected")
    var bomber: Dictionary = game.call("_find_node", "bomber")
    if not game.call("_is_node_unlocked", bomber):
        push_error("W52 tech: bomber failed hangar + reactor requirements")
        return false
    if int(game.get("g")) != g_before:
        push_error("W52 tech: unapproved building prices changed G")
        return false
    game.call("restore_state", {"week":1, "g":g_before, "phase":"dialogue", "dialogue":0,
        "help":1, "placements":[], "buildings":["hq", "robot_factory"]})
    return true




func _check_main_entry() -> bool:
    # The exported game starts at main.tscn, not directly at scenes/game.tscn.
    # Exercise title -> menu -> new game so an old alternate tree cannot slip through.
    var entry_scene: PackedScene = load("res://main.tscn")
    if entry_scene == null:
        push_error("W52 tech: missing exported entry scene")
        return false
    var app: Control = entry_scene.instantiate() as Control
    if app == null:
        push_error("W52 tech: root entry scene is not a Control")
        return false
    root.add_child(app)
    app.call("_show_main_menu")
    app.call("_start_new_game")
    var live: Control = app.get("game_scene") as Control
    var valid: bool = live != null
    if valid:
        var live_nodes: Array = live.get_script().get_script_constant_map().get("NODES", [])
        var full_button: Button = live.get("full_view_button") as Button
        valid = (
            live.get_parent() == app
            and live_nodes.size() == 20
            and live.get_node_or_null("TreeClip") != null
            and full_button != null
            and full_button.text == "전체 기술도"
        )
    root.remove_child(app)
    app.queue_free()
    if not valid:
        push_error("W52 tech: main menu opens an outdated or incomplete game tree")
    return valid


func _run() -> void:
    var game_scene: PackedScene = load("res://scenes/game.tscn")
    if game_scene == null:
        push_error("W52 smoke: missing Game scene")
        quit(1)
        return
    var game: Control = game_scene.instantiate() as Control
    root.add_child(game)
    await process_frame

    if int(ProjectSettings.get_setting("display/window/size/viewport_width")) != 1920:
        push_error("W52 smoke: wrong logical viewport width")
        quit(1)
        return
    if int(ProjectSettings.get_setting("display/window/size/viewport_height")) != 1080:
        push_error("W52 smoke: wrong logical viewport height")
        quit(1)
        return

    if not _check_integrated_tree(game) or not _assert_readable_tree(game) or not _check_tree_pan_and_popup(game):
        quit(1)
        return

    game.set("full_tree_view", false)
    game.call("_refresh_all")
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

        game.call("_select_node", "rifle")
        if str(game.get("selected_id")) != "rifle":
            push_error("W52 smoke: tree node selection failed")
            quit(1)
            return
        game.call("_deploy_selected")
        var allies: Array = game.get("placements")
        if allies.is_empty():
            push_error("W52 smoke: deploy failed")
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
    var version2 := ConfigFile.new()
    version2.set_value("session", "version", 2)
    version2.set_value("session", "week", 24)
    version2.set_value("session", "g", 230)
    version2.set_value("session", "phase", "prepare")
    version2.set_value("session", "dialogue", 5)
    version2.set_value("session", "help", 24)
    version2.set_value("session", "placements", ["guard"])
    if version2.save("user://game_save.cfg") != OK:
        push_error("W52 tech: cannot create v2 fixture")
        quit(1)
        return
    var migrated: Dictionary = store.load_game()
    if int(migrated.get("week", 0)) != 24 or migrated.get("buildings", []).size() != 2:
        push_error("W52 tech: v2 progression migration failed")
        quit(1)
        return
    var saved: Dictionary = game.call("snapshot")
    if not store.save_game(saved):
        push_error("W52 smoke: save failed")
        quit(1)
        return
    var restored: Dictionary = store.load_game()
    if int(restored.get("week", 0)) != 52 or int(restored.get("g", -1)) < 0 or not ("robot_factory" in restored.get("buildings", [])):
        push_error("W52 smoke: restore invalid")
        quit(1)
        return
    var bad: Dictionary = restored.duplicate(true)
    bad["buildings"] = ["hq", "robot_factory", "invalid_building"]
    if store.save_game(bad):
        push_error("W52 tech: unknown building accepted by save writer")
        quit(1)
        return
    bad["buildings"] = ["hq", "robot_factory", "machine_shop"]
    if store.save_game(bad):
        push_error("W52 tech: orphaned machine shop accepted by save writer")
        quit(1)
        return
    bad["week"] = 1
    bad["buildings"] = ["hq", "robot_factory", "walker_factory"]
    if store.save_game(bad):
        push_error("W52 tech: future-week building accepted by save writer")
        quit(1)
        return
    if not store.clear_save():
        push_error("W52 tech: could not clean up test save")
        quit(1)
        return
    if not _check_main_entry():
        quit(1)
        return
    print("W52_UI_SMOKE_OK: 20 nodes, 24 upgrades, facility prerequisites, 52 battles, save v2/v3, 1920x1080")
    quit(0)

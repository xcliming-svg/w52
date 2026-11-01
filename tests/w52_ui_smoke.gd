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


func _check_tree_pan_and_popup(game: Control) -> bool:
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
    game.call("_select_node", "guard")
    game.call("_process", 1.0)
    var center: Vector2 = game.call("_node_screen", game.call("_find_node", "guard"))
    if center.distance_to(Vector2(688, 530)) > 0.1:
        push_error("W52 smoke: focused node not centered")
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
    game.call("_input", _mouse_motion(start + Vector2(3, 2)))
    var under_threshold: Vector2 = game.get("camera_offset")
    if under_threshold.distance_to(before) > 0.1:
        push_error("W52 smoke: under-threshold motion panned tree")
        return false
    game.call("_input", _mouse_motion(start + Vector2(96, 82)))
    var moved: Vector2 = game.get("camera_offset")
    if moved.distance_to(before) < 10:
        push_error("W52 smoke: background drag did not pan tree")
        return false
    game.call("_input", _mouse_button(false, start + Vector2(96, 82)))
    if bool(game.get("pan_armed")) or str(game.get("selected_id")) != "guard":
        push_error("W52 smoke: releasing drag did not end pan cleanly")
        return false
    # Long drags saturate exactly at the limits.
    var bounds: Rect2 = game.call("_pan_limits")
    game.call("_gui_input", _mouse_button(true, start))
    game.call("_input", _mouse_motion(Vector2(9000, 9000)))
    var max_offset: Vector2 = game.get("camera_offset")
    game.call("_input", _mouse_button(false, Vector2(9000, 9000)))
    if max_offset.distance_to(bounds.end) > 0.1:
        push_error("W52 smoke: positive drag exceeded padding bounds")
        return false
    game.call("_gui_input", _mouse_button(true, start))
    game.call("_input", _mouse_motion(Vector2(-9000, -9000)))
    var min_offset: Vector2 = game.get("camera_offset")
    game.call("_input", _mouse_button(false, Vector2(-9000, -9000)))
    if min_offset.distance_to(bounds.position) > 0.1:
        push_error("W52 smoke: negative drag exceeded padding bounds")
        return false
    # A focused edge node still returns to the exact center after dragging.
    game.call("_select_node", "mobility")
    game.call("_process", 1.0)
    center = game.call("_node_screen", game.call("_find_node", "mobility"))
    if center.distance_to(Vector2(688, 530)) > 0.1:
        push_error("W52 smoke: pan clamp blocks node focus")
        return false
    # A short click on a visible node still selects it; dragging that node does not.
    var command_pos: Vector2 = game.call("_node_screen", game.call("_find_node", "command"))
    game.call("_gui_input", _mouse_button(true, command_pos))
    game.call("_input", _mouse_motion(command_pos + Vector2(3, 0)))
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

    if not _check_tree_pan_and_popup(game):
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
    print("W52_UI_SMOKE_OK: 52 battles, dialogues, help gating, deployment, save/restore, 1920x1080")
    quit(0)

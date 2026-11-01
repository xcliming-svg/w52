extends RefCounted

const SAVE_PATH := "user://game_save.cfg"
const SAVE_VERSION := 1


func has_save() -> bool:
    return not load_game().is_empty()


func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var config := ConfigFile.new()
    var error := config.load(SAVE_PATH)
    if error != OK:
        push_warning("Unable to read game save (%s)." % error)
        return {}
    if config.get_value("session", "version", -1) != SAVE_VERSION:
        return {}
    var x: Variant = config.get_value("session", "x", null)
    var y: Variant = config.get_value("session", "y", null)
    if not (x is float or x is int) or not (y is float or y is int):
        return {}
    var pos := Vector2(float(x), float(y))
    if is_nan(pos.x) or is_nan(pos.y) or is_inf(pos.x) or is_inf(pos.y):
        return {}
    if pos.x < 0.0 or pos.x > 960.0 or pos.y < 0.0 or pos.y > 540.0:
        return {}
    return {"position": pos}


func save_game(pos: Vector2) -> bool:
    if is_nan(pos.x) or is_nan(pos.y) or is_inf(pos.x) or is_inf(pos.y):
        push_warning("Refused invalid player position in save.")
        return false
    var config := ConfigFile.new()
    config.set_value("session", "version", SAVE_VERSION)
    config.set_value("session", "x", pos.x)
    config.set_value("session", "y", pos.y)
    var error := config.save(SAVE_PATH)
    if error != OK:
        push_warning("Unable to write game save (%s)." % error)
        return false
    return true


func clear_save() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return true
    var error := DirAccess.remove_absolute(SAVE_PATH)
    if error != OK:
        push_warning("Unable to remove game save (%s)." % error)
        return false
    return true

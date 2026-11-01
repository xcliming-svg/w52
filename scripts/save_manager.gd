extends RefCounted

const SAVE_PATH := "user://game_save.cfg"
const SAVE_VERSION := 2
const MAX_WEEK := 52

func has_save() -> bool:
    return not load_game().is_empty()

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return {}
    var version: int = int(config.get_value("session", "version", -1))
    if version == 1:
        var x: Variant = config.get_value("session", "x", null)
        var y: Variant = config.get_value("session", "y", null)
        if not (x is int or x is float) or not (y is int or y is float):
            return {}
        if is_nan(float(x)) or is_nan(float(y)):
            return {}
        if float(x) < 0 or float(x) > 960 or float(y) < 0 or float(y) > 540:
            return {}
        return {"week":1, "g":160, "phase":"dialogue", "dialogue":0, "help":1, "placements":[]}
    if version != SAVE_VERSION:
        return {}
    var week: Variant = config.get_value("session", "week", null)
    var g: Variant = config.get_value("session", "g", null)
    if not (week is int) or not (g is int):
        return {}
    if week < 1 or week > MAX_WEEK or g < 0 or g > 1000000000:
        return {}
    var phase: String = str(config.get_value("session", "phase", "dialogue"))
    if phase not in ["dialogue", "prepare", "battle", "result"]:
        return {}
    var placements: Variant = config.get_value("session", "placements", [])
    if not (placements is Array) or placements.size() > 12:
        return {}
    for id in placements:
        if not (id is String):
            return {}
    return {"week":week, "g":g, "phase":phase,
        "dialogue":clampi(int(config.get_value("session", "dialogue", 0)),0,5),
        "help":clampi(int(config.get_value("session", "help", week)),1,week),
        "placements":placements}

func save_game(data: Dictionary) -> bool:
    var week: int = int(data.get("week", 0))
    var g: int = int(data.get("g", -1))
    if week < 1 or week > MAX_WEEK or g < 0 or g > 1000000000:
        push_warning("Rejected invalid W52 progress.")
        return false
    var config := ConfigFile.new()
    config.set_value("session", "version", SAVE_VERSION)
    for key in ["week","g","phase","dialogue","help","placements"]:
        config.set_value("session", key, data.get(key))
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

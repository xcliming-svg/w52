extends RefCounted

const SAVE_PATH := "user://game_save.cfg"
const SAVE_VERSION := 4
const MAX_WEEK := 52
const GameRules = preload("res://scripts/game.gd")


func has_save() -> bool:
    return not load_game().is_empty()


func _valid_buildings(buildings: Variant, at_week: int) -> bool:
    if not (buildings is Array) or buildings.size() > 8:
        return false
    if "hq" not in buildings or "robot_factory" not in buildings:
        return false
    var seen: Dictionary = {}
    for id in buildings:
        if not (id is String) or seen.has(id):
            return false
        seen[id] = true
    for id in buildings:
        var found := false
        for node in GameRules.NODES:
            if str(node["id"]) != id:
                continue
            if str(node["kind"]) == "unit" or int(node["week"]) > at_week:
                return false
            var parent: String = str(node["parent"])
            if not parent.is_empty() and parent not in buildings:
                return false
            found = true
            break
        if not found:
            return false
    return true



func _usable_unit(unit_id: String, at_week: int, buildings: Array) -> bool:
    for node in GameRules.NODES:
        if str(node["id"]) != unit_id or str(node["kind"]) != "unit":
            continue
        if int(node["week"]) > at_week:
            return false
        for req in node["requires"]:
            if str(req) not in buildings:
                return false
        return true
    return false


func _valid_placements(items: Variant, at_week: int, buildings: Array) -> bool:
    if not (items is Array) or items.size() > 12:
        return false
    var ids: Dictionary = {}
    var occupied: Dictionary = {}
    var sz: Vector2i = GameRules.grid_size_for_week(at_week)
    for raw in items:
        if not (raw is Dictionary):
            return false
        var entry: Dictionary = raw
        if entry.size() != 4:
            return false
        for key in ["instance_id", "unit_id", "col", "row"]:
            if not entry.has(key):
                return false
        if not (entry["instance_id"] is String) or not (entry["unit_id"] is String) or not (entry["col"] is int) or not (entry["row"] is int):
            return false
        var instance_id: String = entry["instance_id"]
        var unit_id: String = entry["unit_id"]
        var col: int = entry["col"]
        var row: int = entry["row"]
        if instance_id.strip_edges().is_empty() or ids.has(instance_id) or not _usable_unit(unit_id, at_week, buildings):
            return false
        if col < 0 or col >= sz.x or row < int(sz.y / 2) or row >= sz.y:
            return false
        var cell_key := "%d:%d" % [col, row]
        if occupied.has(cell_key):
            return false
        ids[instance_id] = true
        occupied[cell_key] = true
    return true


func _migrate_legacy_placements(items: Array, at_week: int, buildings: Array) -> Array[Dictionary]:
    var converted: Array[Dictionary] = []
    for raw in items:
        if not (raw is String):
            continue
        if not _usable_unit(raw, at_week, buildings):
            continue
        var cell: Vector2i = GameRules.legacy_cell_for_index(converted.size(), at_week)
        converted.append({"instance_id":"legacy_%02d" % (converted.size() + 1),
            "unit_id":raw, "col":cell.x, "row":cell.y})
    return converted


func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return {}
    var version: int = int(config.get_value("session", "version", -1))
    if version not in [2, 3, SAVE_VERSION]:
        return {}
    var at_week: Variant = config.get_value("session", "week", null)
    var stored_g: Variant = config.get_value("session", "g", null)
    if not (at_week is int) or not (stored_g is int):
        return {}
    var week: int = int(at_week)
    var g: int = int(stored_g)
    if week < 1 or week > MAX_WEEK or g < 0 or g > 1000000000:
        return {}
    var phase: String = str(config.get_value("session", "phase", "dialogue"))
    if phase not in ["dialogue", "prepare", "battle", "result"]:
        return {}
    var raw_placements: Variant = config.get_value("session", "placements", [])
    if not (raw_placements is Array) or raw_placements.size() > 12:
        return {}
    var buildings: Variant = ["hq", "robot_factory"]
    if version >= 3:
        buildings = config.get_value("session", "buildings", null)
        if not _valid_buildings(buildings, week):
            return {}
    var placements: Array[Dictionary] = []
    if version == SAVE_VERSION:
        if not _valid_placements(raw_placements, week, buildings):
            return {}
        for entry in raw_placements:
            placements.append((entry as Dictionary).duplicate(true))
    else:
        for id in raw_placements:
            if not (id is String):
                return {}
        placements = _migrate_legacy_placements(raw_placements, week, buildings)
    return {"week":week, "g":g, "phase":phase,
        "dialogue":clampi(int(config.get_value("session", "dialogue", 0)), 0, 5),
        "help":clampi(int(config.get_value("session", "help", week)), 1, week),
        "placements":placements, "buildings":buildings}

func save_game(data: Dictionary) -> bool:
    var week: int = int(data.get("week", 0))
    var g: int = int(data.get("g", -1))
    if week < 1 or week > MAX_WEEK or g < 0 or g > 1000000000:
        push_warning("Rejected invalid W52 progress.")
        return false
    var phase: Variant = data.get("phase", null)
    if not (phase is String) or phase not in ["dialogue", "prepare", "battle", "result"]:
        push_warning("Rejected invalid W52 phase.")
        return false
    var buildings: Variant = data.get("buildings", null)
    if not _valid_buildings(buildings, week):
        push_warning("Rejected invalid W52 building ownership.")
        return false
    var placements: Variant = data.get("placements", null)
    if not _valid_placements(placements, week, buildings):
        push_warning("Rejected invalid W52 unit placements.")
        return false
    var config := ConfigFile.new()
    config.set_value("session", "version", SAVE_VERSION)
    for key in ["week", "g", "phase", "dialogue", "help", "placements", "buildings"]:
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

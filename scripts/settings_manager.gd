extends Node

const SETTINGS_PATH := "user://settings.cfg"
var master_volume: float = 0.8
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false


func _ready() -> void:
    _ensure_bus("Music")
    _ensure_bus("SFX")
    _load_settings()
    _apply_volume("Master", master_volume)
    _apply_volume("Music", music_volume)
    _apply_volume("SFX", sfx_volume)
    if OS.has_feature("web"):
        # Browser security forbids automatic fullscreen at startup.
        fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    else:
        _apply_fullscreen()


func set_volume(bus_name: String, volume: float) -> void:
    var normalized := clampf(volume, 0.0, 1.0)
    match bus_name:
        "Master":
            master_volume = normalized
        "Music":
            music_volume = normalized
        "SFX":
            sfx_volume = normalized
        _:
            return
    _apply_volume(bus_name, normalized)
    _save_settings()


func is_fullscreen() -> bool:
    # Browser Esc and OS window controls can change the actual state outside
    # the settings menu. Read the window rather than a cached preference.
    var mode := DisplayServer.window_get_mode()
    return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
        or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func set_fullscreen(enabled: bool) -> void:
    # Web callers must request fullscreen inside an active input event.
    fullscreen = enabled
    _apply_fullscreen()
    # A saved web fullscreen preference cannot be restored on reload because
    # browsers prohibit fullscreen without a fresh user gesture.
    if not OS.has_feature("web"):
        _save_settings()


func _ensure_bus(bus_name: String) -> void:
    if AudioServer.get_bus_index(bus_name) != -1:
        return
    AudioServer.add_bus()
    var index := AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(index, bus_name)
    AudioServer.set_bus_send(index, "Master")


func _apply_volume(bus_name: String, value: float) -> void:
    var index := AudioServer.get_bus_index(bus_name)
    if index == -1:
        push_warning("Missing audio bus: " + bus_name)
        return
    AudioServer.set_bus_mute(index, value <= 0.0)
    AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))


func _apply_fullscreen() -> void:
    var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
    DisplayServer.window_set_mode(mode)


func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) != OK:
        return
    master_volume = _read_volume(config, "master", master_volume)
    music_volume = _read_volume(config, "music", music_volume)
    sfx_volume = _read_volume(config, "sfx", sfx_volume)
    var saved_fullscreen: Variant = config.get_value("display", "fullscreen", false)
    if saved_fullscreen is bool:
        fullscreen = saved_fullscreen


func _read_volume(config: ConfigFile, key: String, fallback: float) -> float:
    var value: Variant = config.get_value("audio", key, fallback)
    if not (value is float or value is int):
        return fallback
    var number := float(value)
    if is_nan(number) or is_inf(number):
        return fallback
    return clampf(number, 0.0, 1.0)


func _save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "master", master_volume)
    config.set_value("audio", "music", music_volume)
    config.set_value("audio", "sfx", sfx_volume)
    config.set_value("display", "fullscreen", fullscreen)
    var error := config.save(SETTINGS_PATH)
    if error != OK:
        push_warning("Unable to save settings (%s)." % error)

extends Control

const TITLE_SCENE = preload("res://scenes/title.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
const GAME_SCENE = preload("res://scenes/game.tscn")
const PAUSE_MENU_SCENE = preload("res://scenes/pause_menu.tscn")
const DEFEAT_SCENE = preload("res://scenes/defeat_screen.tscn")
const SETTINGS_SCENE = preload("res://scenes/settings_menu.tscn")
const SaveStore = preload("res://scripts/save_manager.gd")
const SettingsStore = preload("res://scripts/settings_manager.gd")
const KOREAN_UI_FONT: Font = preload("res://assets/fonts/ui_ko_subset.woff2")
const KOREAN_FONT_PARTS := [19, 96, 98, 101, 103, 105, 106, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]

enum GameState { TITLE, MAIN_MENU, PLAYING, PAUSED, DEFEAT }

var state: GameState = GameState.TITLE
var save_store = SaveStore.new()
var settings_store: Node
var current_screen: Control
var game_scene: Control
var result_overlay: Control
var settings_overlay: Control


func _ready() -> void:
    # Web builds do not reliably provide system CJK font fallbacks.
    # Include only the licensed Nanum Gothic Unicode ranges used by the new UI.
    var fallback_fonts: Array[Font] = []
    for part in KOREAN_FONT_PARTS:
        var font := load("res://assets/fonts/nanum-%d.woff2" % part) as Font
        if font == null:
            push_error("Missing bundled Korean glyph subset: %d" % part)
        else:
            fallback_fonts.append(font)
    KOREAN_UI_FONT.set_fallbacks(fallback_fonts)
    var ui_theme := Theme.new()
    ui_theme.default_font = KOREAN_UI_FONT
    ui_theme.default_font_size = 26
    theme = ui_theme
    process_mode = Node.PROCESS_MODE_ALWAYS
    settings_store = SettingsStore.new()
    settings_store.name = "SettingsStore"
    add_child(settings_store)
    _show_title()


func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
        return
    if settings_overlay != null:
        _close_settings()
    elif state == GameState.PLAYING:
        _pause_game()
    elif state == GameState.PAUSED:
        _resume_game()
    else:
        return
    get_viewport().set_input_as_handled()


func _show_title() -> void:
    _clear_screen()
    state = GameState.TITLE
    current_screen = TITLE_SCENE.instantiate() as Control
    add_child(current_screen)
    current_screen.connect("finished", Callable(self, "_show_main_menu"))


func _show_main_menu() -> void:
    _close_settings()
    _clear_result_overlay()
    _clear_screen()
    _clear_game()
    get_tree().paused = false
    state = GameState.MAIN_MENU
    current_screen = MAIN_MENU_SCENE.instantiate() as Control
    current_screen.call("set_continue_available", save_store.has_save())
    add_child(current_screen)
    current_screen.connect("new_game_requested", Callable(self, "_start_new_game"))
    current_screen.connect("continue_requested", Callable(self, "_continue_game"))
    current_screen.connect("settings_requested", Callable(self, "_open_settings"))
    current_screen.connect("quit_requested", Callable(self, "_quit_game"))


func _start_new_game() -> void:
    if state != GameState.MAIN_MENU and state != GameState.PAUSED and state != GameState.DEFEAT:
        return
    if settings_overlay != null:
        return
    if not save_store.clear_save():
        push_warning("Previous game save could not be removed.")
    _start_game({})


func _continue_game() -> void:
    if state != GameState.MAIN_MENU or settings_overlay != null:
        return
    var data: Dictionary = save_store.load_game()
    if data.is_empty():
        current_screen.call("set_continue_available", false)
        return
    _start_game(data)


func _start_game(initial_state: Dictionary) -> void:
    get_tree().paused = false
    _close_settings()
    _clear_result_overlay()
    _clear_screen()
    _clear_game()
    game_scene = GAME_SCENE.instantiate() as Control
    game_scene.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(game_scene)
    game_scene.call("restore_state", initial_state)
    game_scene.connect("defeated", Callable(self, "_on_defeated"))
    state = GameState.PLAYING


func _pause_game() -> void:
    if state != GameState.PLAYING or game_scene == null:
        return
    state = GameState.PAUSED
    get_tree().paused = true
    result_overlay = PAUSE_MENU_SCENE.instantiate() as Control
    add_child(result_overlay)
    result_overlay.connect("resume_requested", Callable(self, "_resume_game"))
    result_overlay.connect("restart_requested", Callable(self, "_start_new_game"))
    result_overlay.connect("settings_requested", Callable(self, "_open_settings"))
    result_overlay.connect("main_menu_requested", Callable(self, "_leave_game_to_menu"))


func _resume_game() -> void:
    if state != GameState.PAUSED or settings_overlay != null:
        return
    _clear_result_overlay()
    state = GameState.PLAYING
    get_tree().paused = false


func _leave_game_to_menu() -> void:
    if state != GameState.PAUSED or settings_overlay != null:
        return
    if game_scene != null:
        var progress: Dictionary = game_scene.call("snapshot")
        if not save_store.save_game(progress):
            push_warning("Progress could not be saved before returning to the menu.")
    _show_main_menu()


func _on_defeated() -> void:
    if state != GameState.PLAYING:
        return
    if not save_store.clear_save():
        push_warning("Defeated session save could not be removed.")
    state = GameState.DEFEAT
    get_tree().paused = true
    result_overlay = DEFEAT_SCENE.instantiate() as Control
    add_child(result_overlay)
    result_overlay.connect("restart_requested", Callable(self, "_start_new_game"))
    result_overlay.connect("main_menu_requested", Callable(self, "_show_main_menu"))


func _open_settings() -> void:
    if settings_overlay != null:
        return
    if state != GameState.MAIN_MENU and state != GameState.PAUSED:
        return
    settings_overlay = SETTINGS_SCENE.instantiate() as Control
    settings_overlay.set("settings_store", settings_store)
    add_child(settings_overlay)
    settings_overlay.connect("close_requested", Callable(self, "_close_settings"))


func _close_settings() -> void:
    if settings_overlay == null:
        return
    remove_child(settings_overlay)
    settings_overlay.queue_free()
    settings_overlay = null


func _clear_result_overlay() -> void:
    if result_overlay == null:
        return
    remove_child(result_overlay)
    result_overlay.queue_free()
    result_overlay = null


func _clear_screen() -> void:
    if current_screen == null:
        return
    remove_child(current_screen)
    current_screen.queue_free()
    current_screen = null


func _clear_game() -> void:
    if game_scene == null:
        return
    remove_child(game_scene)
    game_scene.queue_free()
    game_scene = null


func _quit_game() -> void:
    if state == GameState.MAIN_MENU and settings_overlay == null:
        get_tree().quit()

extends Control

signal new_game_requested
signal continue_requested
signal settings_requested
signal quit_requested

const UI = preload("res://scripts/ui_style.gd")
var continue_available: bool = false
var continue_button: Button


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "W52", "메인 메뉴")
    var new_button: Button = UI.make_button("새 게임")
    column.add_child(new_button)
    new_button.pressed.connect(func() -> void: new_game_requested.emit())

    continue_button = UI.make_button("이어하기")
    continue_button.disabled = not continue_available
    column.add_child(continue_button)
    continue_button.pressed.connect(func() -> void: continue_requested.emit())

    var settings_button: Button = UI.make_button("설정")
    column.add_child(settings_button)
    settings_button.pressed.connect(func() -> void: settings_requested.emit())

    var quit_button: Button = UI.make_button("게임 종료")
    column.add_child(quit_button)
    quit_button.pressed.connect(func() -> void: quit_requested.emit())
    new_button.grab_focus()


func set_continue_available(available: bool) -> void:
    continue_available = available
    if is_instance_valid(continue_button):
        continue_button.disabled = not available

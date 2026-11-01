extends Control

signal restart_requested
signal main_menu_requested

const UI = preload("res://scripts/ui_style.gd")


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "패배", "전투가 종료되었습니다", true)
    var retry_button: Button = UI.make_button("다시 시작")
    column.add_child(retry_button)
    retry_button.pressed.connect(func() -> void: restart_requested.emit())

    var menu_button: Button = UI.make_button("메인 메뉴")
    column.add_child(menu_button)
    menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
    retry_button.grab_focus()

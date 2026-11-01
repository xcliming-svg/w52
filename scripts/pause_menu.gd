extends Control

signal resume_requested
signal restart_requested
signal settings_requested
signal main_menu_requested

const UI = preload("res://scripts/ui_style.gd")


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "일시정지", "게임이 정지되었습니다", true)
    var resume_button: Button = UI.make_button("계속하기")
    column.add_child(resume_button)
    resume_button.pressed.connect(func() -> void: resume_requested.emit())

    var restart_button: Button = UI.make_button("다시 시작")
    column.add_child(restart_button)
    restart_button.pressed.connect(func() -> void: restart_requested.emit())

    var settings_button: Button = UI.make_button("설정")
    column.add_child(settings_button)
    settings_button.pressed.connect(func() -> void: settings_requested.emit())

    var menu_button: Button = UI.make_button("메인 메뉴")
    column.add_child(menu_button)
    menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
    resume_button.grab_focus()

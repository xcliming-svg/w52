class_name RStateMachine
extends RefCounted

signal transitioned(from_state: String, to_state: String)

const ALLOWED: Dictionary={
	"BOOT":["TITLE","ERROR"],
	"TITLE":["MENU","ERROR"],
	"MENU":["RUN","SETTINGS","RECORDS","CODEX","ERROR"],
	"RUN":["PAUSE","SETTINGS","DEFEAT","MENU"],
	"PAUSE":["RUN","SETTINGS","DEFEAT","MENU"],
	"SETTINGS":["MENU","RUN","PAUSE"],
	"RESULT":["MENU","RUN"],
	"DEFEAT":["RESULT"],
	"RECORDS":["MENU"],
	"CODEX":["MENU"],
	"ERROR":["MENU"]
}
var current: String="BOOT"

func transition(to: String) -> bool:
	if to==current:
		return true
	if not (to in ALLOWED.get(current,[])):
		return false
	var previous: String=current
	current=to
	transitioned.emit(previous,current)
	return true

func force_boot() -> void:
	current="BOOT"

class_name RBuildVersion
extends RefCounted

const VERSION: String=RBalance.VERSION
const CONTENT_SCHEMA: int=1
const ENGINE_TARGET: String="Godot 4.7.2"
const RELEASE_STATE: String="STATIC_UNVERIFIED"

static func identity() -> String:
	return "RAIL//SURVIVOR "+VERSION+" / "+ENGINE_TARGET+" / "+RELEASE_STATE

static func save_metadata() -> Dictionary:
	return {"game_version":VERSION,"content_schema":CONTENT_SCHEMA,"engine_target":ENGINE_TARGET}

class_name RSaveStore
extends RefCounted

const RUN_FILE := "user://rail_run_v1.json"
const BACKUP_A := "user://rail_run_v1.bak1"
const BACKUP_B := "user://rail_run_v1.bak2"
const SETTING_FILE := "user://rail_settings_v1.json"
const RECORD_FILE := "user://rail_records_v1.json"
const SCHEMA: int = 1

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return json.data

static func _atomic_write(path: String, value: Dictionary) -> bool:
	var temp_path := path + ".tmp"
	var output := FileAccess.open(temp_path, FileAccess.WRITE)
	if output == null:
		return false
	output.store_string(JSON.stringify(value))
	output.flush()
	output.close()
	var source := ProjectSettings.globalize_path(temp_path)
	var dest := ProjectSettings.globalize_path(path)
	var previous := dest + ".swap"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".swap"):
			DirAccess.remove_absolute(previous)
		if DirAccess.rename_absolute(dest, previous) != OK:
			return false
	var err := DirAccess.rename_absolute(source,dest)
	if err != OK:
		if FileAccess.file_exists(path + ".swap"):
			DirAccess.rename_absolute(previous,dest)
		return false
	if FileAccess.file_exists(path + ".swap"):
		DirAccess.remove_absolute(previous)
	return true

static func save_run(snapshot: Dictionary) -> bool:
	if str(snapshot.get("status", "")) != "RUN":
		return false
	var record := {"schema_version":SCHEMA,"game_version":RBalance.VERSION,"run":snapshot}
	if not _valid(record):
		return false
	var existing := _read(RUN_FILE)
	if _valid(existing):
		var backup := _read(BACKUP_A)
		if _valid(backup):
			_atomic_write(BACKUP_B, backup)
		_atomic_write(BACKUP_A, existing)
	return _atomic_write(RUN_FILE, record)

static func _valid(container: Dictionary) -> bool:
	return RSaveSchema.valid(container)


static func load_run() -> Dictionary:
	for file_path in [RUN_FILE,BACKUP_A,BACKUP_B]:
		var record: Dictionary = _read(file_path)
		var migrated: Dictionary=RSaveMigration.migrate(record)
		if not migrated.is_empty():
			return migrated.run
	return {}

static func has_resume() -> bool:
	return not load_run().is_empty()

static func clear_resume() -> void:
	for path in [RUN_FILE,BACKUP_A,BACKUP_B]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func settings() -> Dictionary:
	var result := {
		"master":0.75, "music":0.20, "sfx":0.75, "vfx":1.0,
		"low_flash":true, "shake":true, "color_mode":0, "high_contrast":false,
		"number_scale":1.0, "ui_scale":1.0, "default_speed":1, "tutorial_shown":false
	}
	var stored: Dictionary = _read(SETTING_FILE)
	for key in stored:
		if result.has(key):
			result[key] = stored[key]
	return result

static func save_settings(values: Dictionary) -> bool:
	return _atomic_write(SETTING_FILE,values)

static func add_record(snapshot: Dictionary) -> bool:
	var records: Dictionary = _read(RECORD_FILE)
	var list: Array = records.get("records",[])
	var id: String = "%s:%s:%s" % [str(snapshot.get("seed",0)),str(snapshot.get("tick",0)),str(snapshot.get("end_reason",""))]
	for item in list:
		if str(item.get("id","")) == id:
			return false
	var summary := {"id":id,"seed":snapshot.get("seed",0),"tick":snapshot.get("tick",0),"time_seconds":float(snapshot.get("tick",0))/RBalance.TICK_RATE,"kills":snapshot.get("kills",0),"end_reason":snapshot.get("end_reason",""),"version":RBalance.VERSION,"assisted":snapshot.get("assisted",false),"highest_train":snapshot.get("highest_train",1),"nodes":snapshot.get("nodes",0)}
	list.append(summary)
	if list.size() > 200:
		list.pop_front()
	records.records = list
	return _atomic_write(RECORD_FILE, records)

static func records() -> Array:
	return _read(RECORD_FILE).get("records", [])

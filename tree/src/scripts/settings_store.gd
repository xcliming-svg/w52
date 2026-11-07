class_name RSettingsStore
extends RefCounted

static func get_current() -> Dictionary:
	return RSaveStore.settings()

static func apply(options: Dictionary) -> bool:
	var valid: Dictionary=RSaveStore.settings()
	for key in options:
		if valid.has(key):
			valid[key]=options[key]
	valid.ui_scale=RUiScaling.preset(float(valid.ui_scale))
	valid.number_scale=clampf(float(valid.number_scale),0.7,1.5)
	valid.master=clampf(float(valid.master),0.0,1.0)
	valid.music=clampf(float(valid.music),0.0,1.0)
	valid.sfx=clampf(float(valid.sfx),0.0,1.0)
	valid.vfx=clampf(float(valid.vfx),0.0,1.0)
	valid.color_mode=clampi(int(valid.color_mode),0,3)
	return RSaveStore.save_settings(valid)

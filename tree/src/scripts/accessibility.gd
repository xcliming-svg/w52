class_name RAccessibility
extends RefCounted

static func translate_color(original: Color, mode: int, high_contrast: bool=false) -> Color:
	var color: Color=original
	match clampi(mode,0,3):
		1:
			color=Color(original.r*0.8+original.g*0.2,original.g*0.72+original.r*0.28,original.b,original.a)
		2:
			color=Color(original.r,original.g*0.78+original.b*0.22,original.b*0.68+original.g*0.32,original.a)
		3:
			var luma: float=original.r*0.2126+original.g*0.7152+original.b*0.0722
			color=Color(luma,luma,luma,original.a)
	if high_contrast:
		color=Color(clampf((color.r-0.5)*1.35+0.5,0.0,1.0),clampf((color.g-0.5)*1.35+0.5,0.0,1.0),clampf((color.b-0.5)*1.35+0.5,0.0,1.0),color.a)
	return color

static func low_flash(options: Dictionary) -> bool:
	return bool(options.get("low_flash",true))

static func allow_shake(options: Dictionary) -> bool:
	return bool(options.get("shake",true))

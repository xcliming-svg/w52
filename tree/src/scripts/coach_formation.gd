class_name RCoachFormation
extends RefCounted

# Never creates bodies: all 1–50 cars sample the same arc-length curve.
static func position(head_arclength: float, slot_index: int) -> Vector2:
	return RRailPath.coach_position(head_arclength,slot_index)

static func facing(head_arclength: float, slot_index: int) -> float:
	return RRailPath.heading(head_arclength-float(slot_index)*RBalance.RAIL_SPACING)

static func visual_facing(head_arclength: float, slot_index: int, speed_pixels_per_second: float=RBalance.START_SPEED) -> float:
	var arc: float=arc_spacing(head_arclength,slot_index)
	# A 100ms orientation-only window; position is always the exact rail arc point.
	var width: float=maxf(1.0,speed_pixels_per_second*0.1)
	var half_width: float=width*0.5
	var corners: Array[float]=[0.0,1175.0,1950.0,3125.0]
	for i in corners.size():
		var delta: float=RBalance.positive_mod(arc-corners[i]+RBalance.PERIMETER*0.5,RBalance.PERIMETER)-RBalance.PERIMETER*0.5
		if absf(delta)<=half_width:
			var from_angle: float=(float(i)+3.0)*PI*0.5 if i==0 else float(i-1)*PI*0.5
			var to_angle: float=float(i)*PI*0.5
			return lerp_angle(from_angle,to_angle,clampf((delta+half_width)/width,0.0,1.0))
	return facing(head_arclength,slot_index)

static func count_valid(cars: Array, capacity: int) -> bool:
	return cars.size()>=1 and cars.size()<=mini(RBalance.MAX_TRAIN,capacity)

static func arc_spacing(head_arclength: float, follower_index: int) -> float:
	return RBalance.positive_mod(head_arclength-float(follower_index)*RBalance.RAIL_SPACING,RBalance.PERIMETER)

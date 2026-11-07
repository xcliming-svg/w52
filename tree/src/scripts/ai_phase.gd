class_name RAiPhase
extends RefCounted

static func tick(enemy: Dictionary, delta: float) -> void:
	match str(enemy.ai):
		"blink":
			if fmod(float(enemy.elapsed),6.0)<delta:
				var goal: Vector2=RCornerTargeting.corner_position(int(enemy.target))
				enemy.pos=Vector2(enemy.pos)+(goal-Vector2(enemy.pos)).normalized()*55.0
				enemy.phase_time=0.25
		"absorb_projectile":
			enemy.shield=minf(float(enemy.max_hp)*0.40,float(enemy.shield)+delta*0.2)

static func vulnerable(enemy: Dictionary) -> bool:
	return float(enemy.get("phase_time",0.0))<=0.0

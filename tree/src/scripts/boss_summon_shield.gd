class_name RBossSummonShield
extends RefCounted

static func activate(field, boss: Dictionary, rng: RGameRng) -> int:
	boss.shield = minf(float(boss.max_hp)*0.30,float(boss.shield)+float(boss.max_hp)*0.15)
	if field.templates.size()<=0:
		return 0
	var count: int=0
	for i in 2:
		var pos: Vector2 = Vector2(boss.pos)+Vector2.from_angle(TAU*float(i)/2.0)*40.0
		if field.spawn(field.templates[0],rng,int(boss.target),pos):
			count += 1
	return count

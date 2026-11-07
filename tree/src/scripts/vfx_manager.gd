class_name RVfxManager
extends RVisualEffects

var important_kills: int=0

func on_death(pos: Vector2, scale: float, color: Color) -> void:
	if RPriorityVFX.detailed(scale,density,sparks.size()):
		super.on_death(pos,scale,color)
	else:
		RVfxExplosion.add(sparks,debris_pool,pos,12.0,"compact")
	if scale>=4.0:
		important_kills+=1

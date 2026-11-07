class_name RDamagePipeline
extends RefCounted

# Typed damage event: base + flat, family multiply, global multiply,
# caps, RNG critical. Armor and shield are applied at the target.
static func resolve(base: float, flat_bonus: float, family_factor: float, global_factor: float, crit_chance: float, crit_factor: float, rng: RGameRng) -> Dictionary:
	var damage: float = maxf(0.0,base + flat_bonus)
	damage *= maxf(0.0,family_factor)
	damage *= maxf(0.0,global_factor)
	damage = clampf(damage,0.0,100000000.0)
	return RCriticalSystem.roll(damage,crit_chance,crit_factor,rng)

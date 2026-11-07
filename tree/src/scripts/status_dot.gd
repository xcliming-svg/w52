class_name RStatusDot
extends RefCounted

# Each burn stack is independent and advances every 0.25 game seconds.
static func add(enemy: Dictionary, power: float, seconds: float) -> void:
	var burns: Array=enemy.burn
	while burns.size()>=3:
		burns.pop_front()
	burns.append({"dps":maxf(0.0,power),"time":maxf(0.0,seconds),"carry":0.0,"serial":int(enemy.get("burn_serial",0))})
	enemy.burn_serial=int(enemy.get("burn_serial",0))+1

static func tick(enemy: Dictionary, delta: float, field, game_tick: int) -> void:
	var burns: Array=enemy.burn
	for i in range(burns.size()-1,-1,-1):
		var burn: Dictionary=burns[i]
		burn.time=maxf(0.0,float(burn.time)-delta)
		burn.carry=float(burn.carry)+delta
		while float(burn.carry)>=0.25:
			burn.carry=float(burn.carry)-0.25
			var id: String="dot:%d:%d:%d" % [int(enemy.uid),int(burn.get("serial",i)),game_tick]
			field.apply_damage(int(enemy.uid),float(burn.dps)*0.25,"fire",id,false)
			if str(enemy.state)!="alive":
				break
		if float(burn.time)<=0.0:
			burns.remove_at(i)

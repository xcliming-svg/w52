class_name RDamageNumbers
extends RefCounted

const MERGE_SECONDS: float=0.100
const LIFE_SECONDS: float=0.550

static func accept(numbers: Array[Dictionary], uid: int, amount: float, at: Vector2, kind: String, critical: bool, time: float) -> bool:
	for n in numbers:
		if int(n.uid)==uid and str(n.kind)==kind and time-float(n.start)<MERGE_SECONDS:
			n.amount=float(n.amount)+amount
			n.critical=bool(n.critical) or critical
			n.start=time
			n.age=0.0
			return false
	if numbers.size()>=RBalance.VFX_DAMAGE_CAP:
		# Preserve overflow damage in an existing aggregate, never drop combat damage.
		if not numbers.is_empty():
			numbers[0].amount=float(numbers[0].amount)+amount
		return true
	numbers.append({"uid":uid,"amount":amount,"pos":at,"kind":kind,"critical":critical,"start":time,"age":0.0,"life":LIFE_SECONDS})
	return false

static func paint(canvas: CanvasItem, numbers: Array[Dictionary], size_factor: float=1.0) -> void:
	for n in numbers:
		var alpha: float=1.0-float(n.age)/maxf(0.001,float(n.life))
		var color: Color=Color("#ffdf8b") if bool(n.critical) else Color.WHITE
		match str(n.kind):
			"fire":color=Color("#ff825a")
			"cold":color=Color("#8edff6")
			"electric":color=Color("#c4d4ff")
		color.a=alpha
		var msg: String=String.num(float(n.amount),1)
		if bool(n.critical):
			msg="!"+msg
		canvas.draw_string(ThemeDB.fallback_font,Vector2(n.pos)+Vector2(-14,-20-float(n.age)*45.0),msg,HORIZONTAL_ALIGNMENT_LEFT,-1,int(17.0*clampf(size_factor,0.7,1.5)),color)

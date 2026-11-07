class_name RVisualEffects
extends RefCounted

var sparks: Array[Dictionary]=[]
var numbers: Array[Dictionary]=[]
var flashes: Array[Dictionary]=[]
var overflow_damage_log: Array[Dictionary]=[]
var debris_pool:=RDebrisPool.new()
var rng:=RandomNumberGenerator.new()
var low_flash: bool=true
var density: float=1.0
var configured_density: float=1.0
var time: float=0.0
var shake: float=0.0
var flashes_this_second: int=0
var flash_window_seconds: float=0.0
var number_scale: float=1.0

func configure(options: Dictionary) -> void:
	low_flash=bool(options.get("low_flash",true))
	configured_density=clampf(float(options.get("vfx",1.0)),0.0,1.0)
	density=configured_density
	number_scale=clampf(float(options.get("number_scale",1.0)),0.70,1.5)

func set_density(enemy_count: int) -> void:
	density=RVfxBudget.quality(configured_density,enemy_count)

func tick(delta: float) -> void:
	time+=delta
	flash_window_seconds+=delta
	if flash_window_seconds>=1.0:
		flash_window_seconds=0.0
		flashes_this_second=0
	shake=RVfxScreenShake.fade(shake,delta)
	for list in [sparks,numbers,flashes]:
		for i in range(list.size()-1,-1,-1):
			var fx: Dictionary=list[i]
			fx.age=float(fx.age)+delta
			if list==sparks and not bool(fx.get("ring",false)):
				RDebrisPhysics.step(fx,delta)
			if float(fx.age)>=float(fx.life):
				if list==sparks:
					debris_pool.release(fx)
				list.remove_at(i)

func on_damage(uid: int, amount: float, where: Vector2, kind: String, crit: bool) -> void:
	if RDamageNumbers.accept(numbers,uid,amount,where,kind,crit,time):
		overflow_damage_log.append({"uid":uid,"amount":amount,"type":kind,"time":time})
		if overflow_damage_log.size()>1024:
			overflow_damage_log.pop_front()
	if RVfxLightGuard.allowed_flash({"low_flash":low_flash},flashes_this_second):
		RHitFlash.add(flashes,where,low_flash)
		flashes_this_second+=1

func on_death(pos: Vector2, scale: float, color: Color) -> void:
	RDebrisSplit.scatter(sparks,debris_pool,pos,scale,color,rng,density)
	shake=RVfxScreenShake.impulse(shake,scale,density)

func on_blast(pos: Vector2, radius: float, family: String) -> void:
	RVfxExplosion.add(sparks,debris_pool,pos,radius,family)

func clear() -> void:
	sparks.clear()
	numbers.clear()
	flashes.clear()
	overflow_damage_log.clear()
	debris_pool.free_all()
	time=0.0
	shake=0.0

func draw(canvas: CanvasItem) -> void:
	var point_rects: Array=[]
	var point_colors: Array[Color]=[]
	for spark in sparks:
		var remaining: float=1.0-float(spark.age)/maxf(0.001,float(spark.life))
		var col: Color=spark.color
		col.a=remaining*0.85
		if bool(spark.get("ring",false)):
			canvas.draw_arc(Vector2(spark.pos),float(spark.size)*(1.0-remaining*0.2),0.0,TAU,24,col,2.5,true)
		else:
			var radius: float=float(spark.size)*0.5
			point_rects.append(Rect2(Vector2(spark.pos)-Vector2.ONE*radius,Vector2.ONE*radius*2.0))
			point_colors.append(col)
	RRenderBatch.draw_many_rects(canvas,point_rects,point_colors)
	RDamageNumbers.paint(canvas,numbers,number_scale)
	RHitFlash.paint(canvas,flashes,low_flash)

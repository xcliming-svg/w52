class_name RPhysicsBridge
extends Node2D

# Sparse physical objects only: Boss and selected important actors.
# All gameplay hit checks remain in arrays and swept segments; decorative bodies
# are excluded from attack collision masks.
var tracked_bodies: Dictionary={}
var maximal_bodies: int=96

func _ready() -> void:
	maximal_bodies=40 if OS.has_feature("web") else 96
	visible=false

func sync_bosses(field: REnemyField) -> void:
	var alive: Dictionary={}
	for e in field.enemies:
		if str(e.state)!="alive" or str(e.ai)!="boss_pattern":
			continue
		var uid: int=int(e.uid)
		alive[uid]=true
		if not tracked_bodies.has(uid):
			if tracked_bodies.size()>=maximal_bodies:
				continue
			var body:=RigidBody2D.new()
			body.name="BossBody_%d" % uid
			body.freeze=true
			body.collision_layer=RCollisionLayers.BOSS
			body.collision_mask=RCollisionLayers.TRAIN
			body.contact_monitor=false
			var collision:=CollisionShape2D.new()
			var shape:=CircleShape2D.new()
			shape.radius=maxf(10.0,float(e.size)*0.45)
			collision.shape=shape
			body.add_child(collision)
			add_child(body)
			tracked_bodies[uid]=body
		var node: RigidBody2D=tracked_bodies[uid]
		node.position=Vector2(e.pos)
	for uid in tracked_bodies.keys():
		if not alive.has(uid):
			var node: RigidBody2D=tracked_bodies[uid]
			node.queue_free()
			tracked_bodies.erase(uid)

func clear() -> void:
	for node in tracked_bodies.values():
		if is_instance_valid(node):
			node.queue_free()
	tracked_bodies.clear()

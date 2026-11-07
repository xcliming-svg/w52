class_name RMusicManager
extends Node

# Low-volume original ambient oscillator with state-specific timbres.
var player: AudioStreamPlayer
var mode: String="MENU"
var settings: Dictionary={}
var unlocked: bool=false

func _ready() -> void:
	player=AudioStreamPlayer.new()
	add_child(player)
	player.finished.connect(_on_music_finished)
	set_mode("MENU")

func set_mode(value: String) -> void:
	mode=value
	if player==null:
		return
	var frequency: float=110.0
	match mode:
		"MENU":frequency=120.0
		"RUN":frequency=174.0
		"BOSS":frequency=76.0
	player.stream=RSfxGenerator.tone(frequency,1.20,0.04,1)
	if unlocked:
		player.play()

func apply(options: Dictionary) -> void:
	settings=options.duplicate(true)
	if player!=null:
		var volume: float=clampf(float(settings.get("master",0.75))*float(settings.get("music",0.20)),0.0,1.0)
		player.volume_db=linear_to_db(maxf(0.0001,volume))
		player.stream_paused=volume<=0.001

func activate_after_input() -> void:
	unlocked=true
	if player!=null and not player.playing:
		player.play()

func _on_music_finished() -> void:
	if unlocked and player!=null and float(settings.get("music",0.2))>0.0:
		player.play()

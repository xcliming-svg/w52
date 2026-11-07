class_name RAudioRouter
extends Node

# Synthesized in-project effects: no external recordings or royalty constraints.
const LIMITS: Dictionary = RAudioPolyphony.LIMITS
const GROUP_GAP_MS: int = RAudioPolyphony.GROUP_MS
var pools: Dictionary = {}
var next_player: Dictionary = {}
var last_time: Dictionary = {}
var sounds: Dictionary = {}
var unlocked: bool = false
var browser_policy := RBrowserAudio.new()
var music: RMusicManager
var audio_settings: Dictionary = {}

func _ready() -> void:
	sounds = {
		"fire":_tone(820.0,0.08,0.10,0),
		"blast":_tone(124.0,0.24,0.13,1),
		"warning":_tone(400.0,0.42,0.12,2),
		"ui":_tone(620.0,0.09,0.07,0)
	}
	music=RMusicManager.new()
	add_child(music)
	music.apply(audio_settings)
	music.set_mode("RUN")
	for category in LIMITS.keys():
		var players: Array = []
		for _i in RAudioPolyphony.cap(category):
			var player := AudioStreamPlayer.new()
			player.stream = sounds[category]
			player.bus = "Master"
			add_child(player)
			players.append(player)
		pools[category] = players
		next_player[category] = 0
		last_time[category] = -10000000

func _tone(pitch: float, seconds: float, level: float, waveform: int) -> AudioStreamWAV:
	return RSfxGenerator.tone(pitch,seconds,level,waveform)

func set_options(options: Dictionary) -> void:
	audio_settings = options.duplicate(true)
	if music!=null:
		music.apply(audio_settings)

func allow_from_user_input() -> void:
	browser_policy.user_interacted=true
	unlocked = browser_policy.may_play()
	if music!=null:
		music.activate_after_input()

func play_category(category: String) -> void:
	if not unlocked or not browser_policy.may_play() or not pools.has(category):
		return
	var now: int = Time.get_ticks_msec()
	if not RAudioPolyphony.available(category,int(last_time[category]),now):
		return
	last_time[category] = now
	var group: Array = pools[category]
	var cursor: int = int(next_player[category])
	var player: AudioStreamPlayer = group[cursor]
	next_player[category] = RAudioPolyphony.next_player(cursor,category)
	var master: float = float(audio_settings.get("master",0.75))
	var sfx: float = float(audio_settings.get("sfx",0.75))
	if master*sfx <= 0.001:
		return
	player.volume_db = linear_to_db(maxf(0.0001,master*sfx))
	player.stop()
	player.play()

func on_weapon(_family: String, _source: Vector2, _dest: Vector2) -> void:
	play_category("fire")

func on_blast(_source: Vector2, _radius: float, family: String) -> void:
	if family not in ["warning","support"]:
		play_category("blast")

func on_warning(_description: String, _position: Vector2) -> void:
	play_category("warning")

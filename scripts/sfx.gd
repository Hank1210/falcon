class_name Sfx
extends Node
## Soundeffekte. Einmalklaenge per play(), Dauerklaenge (Triebwerk, Alarm,
## Tanken) per set_loop(). Die WAVs erzeugt tools/make_sounds.py.

const SOUNDS := ["shot", "explosion", "explosion_big", "crash", "bomb_drop", "engine", "alarm", "refuel", "standby", "extra", "beep", "fanfare"]
const LOOPS := ["engine", "alarm", "refuel"]
## Gesamtlautstaerke aller Effekte in dB (Rechteckwellen sind sehr laut).
const MASTER_DB := -9.0
const VOICES := {"shot": 3, "explosion": 3, "explosion_big": 2}

var _players: Dictionary = {}  ## name -> Array[AudioStreamPlayer]
var _loop_on: Dictionary = {}


func _ready() -> void:
	for n in SOUNDS:
		var stream: AudioStreamWAV = load("res://assets/audio/%s.wav" % n)
		if n in LOOPS:
			stream = stream.duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = stream.data.size() / 2  # 16 Bit, mono
		var list: Array[AudioStreamPlayer] = []
		for i in int(VOICES.get(n, 1)):
			var p := AudioStreamPlayer.new()
			p.stream = stream
			add_child(p)
			list.append(p)
		_players[n] = list


func has_sound(n: String) -> bool:
	return _players.has(n) and not _players[n].is_empty() and _players[n][0].stream != null


func play(n: String, pitch := 1.0, volume_db := 0.0) -> void:
	var list: Array = _players[n]
	var voice: AudioStreamPlayer = list[0]
	for p in list:
		if not p.playing:
			voice = p
			break
	voice.pitch_scale = pitch
	voice.volume_db = volume_db + MASTER_DB
	voice.play()


## Schaltet einen Dauerklang an/aus; Lautstaerke und Tonhoehe lassen sich laufend aendern.
func set_loop(n: String, on: bool, volume_db := 0.0, pitch := 1.0) -> void:
	var p: AudioStreamPlayer = _players[n][0]
	if on:
		p.volume_db = volume_db + MASTER_DB
		p.pitch_scale = pitch
		if not _loop_on.get(n, false):
			p.play()
	elif _loop_on.get(n, false):
		p.stop()
	_loop_on[n] = on


func is_loop_on(n: String) -> bool:
	return _loop_on.get(n, false)


func stop_all() -> void:
	for n in _players:
		for p in _players[n]:
			p.stop()
	_loop_on.clear()

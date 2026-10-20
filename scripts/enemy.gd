class_name Enemy
extends Sprite2D
## Feindlicher Jet. Platzhalter-KI: fliegt abwechselnd Angriffe auf den Jet
## und Bombenanfluege auf Flugplaetze (Anker), dreht nach `turn_distance`
## hinter dem Anker um. Position: linke obere Ecke, Welt-x.

var world_x := 0.0
var dir := 1
var target_y := 60.0
var hunting_jet := true  ## Anker ist der Spieler (sonst `pad_anchor_x`)
var pad_anchor_x := 0.0
var bomb_cooldown := 0.0
var aim_error := 0.0  ## Zielfehler (px) beim naechsten Bombenwurf
var leaving := false  ## Welle laeuft aus: geradeaus davonfliegen

var _top: float
var _bottom: float


func _ready() -> void:
	centered = false
	flip_h = dir < 0
	_top = Params.val("screen", "sky_top")
	_bottom = Params.val("screen", "ground_y") - texture.get_height() - 4.0


func step(dt: float, jet_x: float, jet_y: float, pads: Array[float], rng: RandomNumberGenerator) -> void:
	bomb_cooldown = maxf(bomb_cooldown - dt, 0.0)
	world_x = fposmod(world_x + dir * Params.val("enemy", "speed") * dt, Params.val("world", "width"))
	if not leaving:
		var anchor := jet_x if hunting_jet else pad_anchor_x
		# >0, sobald der Gegner in Flugrichtung weit hinter dem Anker ist
		if Wrap.dx(world_x, anchor) * dir > Params.val("enemy", "turn_distance"):
			_turn(jet_y, pads, rng)
	position.y = move_toward(position.y, target_y, Params.val("enemy", "climb_speed") * dt)


func _turn(jet_y: float, pads: Array[float], rng: RandomNumberGenerator) -> void:
	dir = -dir
	flip_h = dir < 0
	if not pads.is_empty() and rng.randf() < Params.val("enemy", "pad_attack_chance"):
		hunting_jet = false
		pad_anchor_x = pads[rng.randi() % pads.size()]
		target_y = rng.randf_range(_top + 20.0, Params.val("screen", "ground_y") - 60.0)
	else:
		hunting_jet = true
		target_y = clampf(jet_y + rng.randf_range(-24.0, 24.0), _top, _bottom)


func center_x() -> float:
	return world_x + texture.get_width() * 0.5


func center_y() -> float:
	return position.y + texture.get_height() * 0.5

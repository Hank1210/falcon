class_name Explosion
extends Node2D
## Pixel-Explosion aus kleinen Quadraten in C64-Farben.

const COLORS := [C64.WHITE, C64.YELLOW, C64.LIGHT_RED, C64.RED]

var world_x := 0.0
var world_y := 0.0
var age := 0.0
var life := 0.5
var radius := 14.0


func setup(wx: float, wy: float, big: bool) -> void:
	world_x = wx
	world_y = wy
	life = 0.9 if big else 0.5
	radius = 24.0 if big else 14.0


func step(dt: float) -> bool:
	age += dt
	queue_redraw()
	return age < life


func _draw() -> void:
	var t := age / life
	var n := 28
	for i in n:
		var a := float(i) / n * TAU + float(i % 3) * 0.4
		var r := t * radius * (0.5 + 0.5 * fposmod(i * 0.37, 1.0))
		var p := (Vector2(cos(a), sin(a)) * r).round()
		var size := 1.0 if t < 0.6 else 0.5
		draw_rect(Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size)), COLORS[(i + int(age * 20.0)) % COLORS.size()])
	if t < 0.25:
		draw_rect(Rect2(-2, -2, 4, 4), C64.WHITE)
		draw_rect(Rect2(-1, -1, 2, 2), C64.YELLOW)

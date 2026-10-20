class_name Missile
extends Node2D
## Rakete des Spielers. Position ist die linke obere Ecke in Weltkoordinaten.

const WIDTH := 5.0
const HEIGHT := 1.0

var world_x := 0.0
var vx := 0.0
var life := 0.0


func step(dt: float) -> bool:
	## Gibt false zurueck, wenn die Rakete verbraucht ist.
	world_x = fposmod(world_x + vx * dt, Params.val("world", "width"))
	life -= dt
	return life > 0.0


func center_x() -> float:
	return world_x + WIDTH * 0.5


func _draw() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), C64.WHITE)
	var tail := -3.0 if vx > 0.0 else WIDTH
	draw_rect(Rect2(tail, 0, 3, HEIGHT), C64.YELLOW)

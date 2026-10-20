class_name Debris
extends Node2D
## Fallende Objekte: Bomben der Gegner und abgeschossene Wracks.
## Position: linke obere Ecke, Welt-x.

enum Kind { BOMB, WRECK }

const TEXTURE := preload("res://assets/sprites/jet.png")
const WRECK_COLOR := C64.LIGHT_RED

var kind := Kind.BOMB
var world_x := 0.0
var vx := 0.0
var vy := 0.0


func width() -> float:
	return 2.0 if kind == Kind.BOMB else float(TEXTURE.get_width())


func height() -> float:
	return 4.0 if kind == Kind.BOMB else float(TEXTURE.get_height())


func center_x() -> float:
	return world_x + width() * 0.5


func center_y() -> float:
	return position.y + height() * 0.5


func bottom_y() -> float:
	return position.y + height()


func step(dt: float) -> void:
	var g := Params.val("enemy", "bomb_gravity" if kind == Kind.BOMB else "wreck_gravity")
	vy += g * dt
	position.y += vy * dt
	world_x = fposmod(world_x + vx * dt, Params.val("world", "width"))


func _draw() -> void:
	if kind == Kind.BOMB:
		draw_rect(Rect2(0, 0, 2, 3), C64.LIGHT_GREY)
		draw_rect(Rect2(0, 3, 2, 1), C64.WHITE)
	else:
		draw_texture(TEXTURE, Vector2.ZERO, WRECK_COLOR)

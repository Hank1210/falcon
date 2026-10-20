class_name Overlay
extends Node2D
## Menue- und Hinweistexte ueber dem Spielfeld. Zeilen sind horizontal zentriert.

var lines: Array[Dictionary] = []
var _signature := ""


## Jede Zeile: {t: Text, y: Pixel, s: Skalierung, c: Farbe, blink: bool}
func set_lines(new_lines: Array[Dictionary]) -> void:
	var sig := str(new_lines)
	if sig != _signature:
		_signature = sig
		lines = new_lines
		queue_redraw()


func _process(_delta: float) -> void:
	for l in lines:
		if l.get("blink", false):
			queue_redraw()
			return


func _draw() -> void:
	var width := Params.val("screen", "width")
	var on := (Engine.get_physics_frames() / 30) % 2 == 0
	for l in lines:
		if l.get("blink", false) and not on:
			continue
		var s: int = l.get("s", 1)
		var x := roundf((width - PixelFont.text_width(l.t, s)) * 0.5)
		PixelFont.draw_text(self, l.t, Vector2(x, l.y), l.c, s)

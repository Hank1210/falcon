class_name Overlay
extends Node2D
## Menue- und Hinweistexte ueber dem Spielfeld. Zeilen sind horizontal zentriert.

var lines: Array[Dictionary] = []
var panel := Rect2()  ## halbtransparenter Hintergrund (leer = keiner)
var _signature := ""


## Jede Zeile: {t: Text, y: Pixel, s: Skalierung, c: Farbe, blink: bool}
func set_lines(new_lines: Array[Dictionary], new_panel := Rect2()) -> void:
	var sig := str(new_lines) + str(new_panel)
	if sig != _signature:
		_signature = sig
		lines = new_lines
		panel = new_panel
		queue_redraw()


func _process(_delta: float) -> void:
	for l in lines:
		if l.get("blink", false):
			queue_redraw()
			return


func _draw() -> void:
	if panel.size != Vector2.ZERO:
		draw_rect(panel, Color(0, 0, 0, 0.6))
	var width := Params.val("screen", "width")
	var on := (Engine.get_physics_frames() / 30) % 2 == 0
	for l in lines:
		if l.get("blink", false) and not on:
			continue
		var s: int = l.get("s", 1)
		var x := roundf((width - PixelFont.text_width(l.t, s)) * 0.5)
		PixelFont.draw_text(self, l.t, Vector2(x, l.y), l.c, s)

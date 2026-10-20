class_name Crt
extends Node2D
## Dezente Scanlines (jede zweite Bildzeile leicht abgedunkelt). Mit C ein/aus.


func _ready() -> void:
	visible = false


func _draw() -> void:
	var w := Params.val("screen", "width")
	var h := int(Params.val("screen", "height"))
	for y in range(1, h, 2):
		draw_rect(Rect2(0, y, w, 1), Color(0, 0, 0, 0.22))

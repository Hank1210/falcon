class_name World
extends Node2D
## Platzhalter-Landschaft, Landeplaetze und Radar. Wird komplett per _draw
## gezeichnet; die Welt wiederholt sich nach `world.width` Pixeln.

var cam_x := 0.0
var jet_world_x := 0.0
var jet_vx := 0.0
var jet_max_speed := 1.0
var score := 0
var lives := 0
var ammo := 0
var ammo_max := 1
var radar_enemies: Array[float] = []
var fuel := 0.0
var hiscore := 0
var fuel_max := 1.0

const TEXTURES := {
	"palm": preload("res://assets/sprites/palm.png"),
	"tank": preload("res://assets/sprites/tank.png"),
	"building": preload("res://assets/sprites/building.png"),
	"truck": preload("res://assets/sprites/truck.png"),
}

var _features: Array[Dictionary] = []
var _pads: Array[float] = []
var _pad_alive: Array[bool] = []
var _world_w: float
var _screen_w: float
var _ground_y: float


func _ready() -> void:
	_world_w = Params.val("world", "width")
	_screen_w = Params.val("screen", "width")
	_ground_y = Params.val("screen", "ground_y")
	_build_world()


func _build_world() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Params.val("world", "seed"))
	var pad_count := int(Params.val("world", "pad_count"))
	var spacing := _world_w / pad_count
	for i in pad_count:
		_pads.append(i * spacing + spacing * 0.5)
		_pad_alive.append(true)
	var types := ["palm", "palm", "tank", "building", "truck"]
	var x := 20.0
	while x < _world_w - 20.0:
		if not _near_pad(x, 36.0):
			_features.append({"type": types[rng.randi() % types.size()], "x": x})
		x += rng.randf_range(34.0, 70.0)


func _near_pad(x: float, margin: float) -> bool:
	var half := Params.val("world", "pad_width") * 0.5 + margin
	for p in _pads:
		if absf(x - p) < half:
			return true
	return false


func to_screen_x(world_x: float) -> float:
	## Bildschirm-x eines Welt-x, im Bereich [-64, world_w - 64).
	return fposmod(world_x - roundf(cam_x) + 64.0, _world_w) - 64.0


## Index des Landeplatzes unter Welt-x (-1 = keiner). `margin` verengt den
## Bereich links und rechts. Zerstoerte Plaetze zaehlen nicht, wenn alive_only.
func pad_index_at(world_x: float, margin := 0.0, alive_only := true) -> int:
	var half := Params.val("world", "pad_width") * 0.5 - margin
	for i in _pads.size():
		if alive_only and not _pad_alive[i]:
			continue
		if absf(Wrap.dx(world_x, _pads[i])) <= half:
			return i
	return -1


func pad_center(i: int) -> float:
	return _pads[i]


func pad_alive(i: int) -> bool:
	return _pad_alive[i]


func pad_total() -> int:
	return _pads.size()


func alive_pad_count() -> int:
	return _pad_alive.count(true)


func alive_pad_centers() -> Array[float]:
	var out: Array[float] = []
	for i in _pads.size():
		if _pad_alive[i]:
			out.append(_pads[i])
	return out


func nearest_pad(world_x: float) -> int:
	var best := 0
	for i in _pads.size():
		if absf(Wrap.dx(_pads[i], world_x)) < absf(Wrap.dx(_pads[best], world_x)):
			best = i
	return best


func destroy_pad(i: int) -> void:
	_pad_alive[i] = false


func restore_pads() -> void:
	for i in _pad_alive.size():
		_pad_alive[i] = true


func _draw_digits(text: String, pos: Vector2, color: Color) -> void:
	PixelFont.draw_text(self, text, pos, color)


func _draw() -> void:
	var ground_h := Params.val("screen", "ground_height")
	draw_rect(Rect2(0, 0, _screen_w, _ground_y), C64.BLUE)
	draw_rect(Rect2(0, _ground_y, _screen_w, ground_h), C64.YELLOW)
	var base := _ground_y + 6.0
	for f in _features:
		var sx := to_screen_x(f.x)
		if sx > _screen_w:
			continue
		var tex: Texture2D = TEXTURES[f.type]
		draw_texture(tex, Vector2(sx, base - tex.get_height()))
	var pad_w := Params.val("world", "pad_width")
	for i in _pads.size():
		var sx := to_screen_x(_pads[i] - pad_w * 0.5)
		if sx > _screen_w:
			continue
		if _pad_alive[i]:
			draw_rect(Rect2(sx, _ground_y, pad_w, 3), C64.LIGHT_GREY)
			draw_rect(Rect2(sx, _ground_y + 3, pad_w, 5), C64.GREY)
		else:
			draw_rect(Rect2(sx, _ground_y, pad_w, 8), C64.BLACK)
			draw_rect(Rect2(sx + 4, _ground_y + 5, 6, 3), C64.DARK_GREY)
			draw_rect(Rect2(sx + 22, _ground_y + 4, 8, 4), C64.DARK_GREY)
	_draw_hud()


func _draw_hud() -> void:
	var top := Params.val("screen", "hud_top")
	draw_rect(Rect2(0, top, _screen_w, Params.val("screen", "height") - top), C64.BLACK)
	var radar := Rect2(100, top + 6, 120, 28)
	draw_rect(radar, C64.DARK_GREY, false)
	var scale := radar.size.x / _world_w
	for i in _pads.size():
		if _pad_alive[i]:
			draw_rect(Rect2(radar.position.x + _pads[i] * scale - 1, radar.position.y + radar.size.y - 4, 3, 2), C64.LIGHT_GREEN)
	var view := Rect2(radar.position.x + fposmod(cam_x, _world_w) * scale, radar.position.y, _screen_w * scale, radar.size.y)
	draw_rect(view, C64.GREY, false)
	_draw_speed_gauge(top)
	_draw_digits("%05d" % score, Vector2(16, top + 26), C64.WHITE)
	_draw_digits("HI %05d" % hiscore, Vector2(232, top + 26), C64.LIGHT_GREY)
	for i in lives:
		draw_rect(Rect2(232 + i * 10, top + 8, 8, 3), C64.WHITE)
	var fuel_len := 36.0 * fuel / fuel_max
	var low := fuel < Params.val("jet", "fuel_low") and (Engine.get_physics_frames() / 15) % 2 == 0
	draw_rect(Rect2(232, top + 14, 36, 3), C64.DARK_GREY)
	draw_rect(Rect2(232, top + 14, fuel_len, 3), C64.LIGHT_RED if low else C64.LIGHT_GREEN)
	for i in ammo_max:
		draw_rect(Rect2(232 + i * 3, top + 20, 2, 5), C64.LIGHT_GREEN if i < ammo else C64.DARK_GREY)
	for ex in radar_enemies:
		draw_rect(Rect2(radar.position.x + ex * scale - 1, radar.position.y + radar.size.y * 0.4, 2, 2), C64.LIGHT_RED)
	draw_rect(Rect2(radar.position.x + jet_world_x * scale - 1, radar.position.y + radar.size.y * 0.4, 2, 2), C64.WHITE)


## Tempoanzeige links vom Radar: Mitte = Stillstand, Ausschlag in Flugrichtung.
## Beim Stillstand leuchtet die Mitte gruen (Landung moeglich).
func _draw_speed_gauge(top: float) -> void:
	var box := Rect2(16, top + 14, 70, 8)
	var mid := box.position.x + box.size.x * 0.5
	draw_rect(box, C64.DARK_GREY, false)
	var len := jet_vx / jet_max_speed * (box.size.x * 0.5 - 2.0)
	if absf(jet_vx) < 1.0:
		draw_rect(Rect2(mid - 1, box.position.y + 2, 2, box.size.y - 4), C64.LIGHT_GREEN)
	else:
		draw_rect(Rect2(minf(mid, mid + len), box.position.y + 2, absf(len), box.size.y - 4), C64.WHITE)

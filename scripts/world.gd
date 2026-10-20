class_name World
extends Node2D
## Himmel, Horizont mit Flugplaetzen, Bodenflaeche mit Strassen und Gebaeuden
## (Draufsicht-Schraege wie im Original) und das HUD. Wird per _draw gezeichnet;
## die Welt wiederholt sich nach `world.width` Pixeln.

const PAD_TEXTURE := preload("res://assets/sprites/pad.png")
const LIFE_ICON := preload("res://assets/sprites/life_icon.png")
const DECOR := {
	"building": preload("res://assets/sprites/building.png"),
	"building_tall": preload("res://assets/sprites/building_tall.png"),
	"palm": preload("res://assets/sprites/palm.png"),
	"tank": preload("res://assets/sprites/tank.png"),
	"truck": preload("res://assets/sprites/truck.png"),
	"truck_black": preload("res://assets/sprites/truck_black.png"),
}

# Abstaende (px) unterhalb des Horizonts
const FAR_ROAD := 12
const MAIN_ROAD := 38
const ROAD_THICKNESS := 6

var cam_x := 0.0
var jet_center_x := 0.0
var jet_vx := 0.0
var jet_max_speed := 1.0
var score := 0
var hiscore := 0
var lives := 0
var ammo := 0
var fuel := 0.0
var fuel_max := 1.0
var radar_enemies: Array[Vector2] = []  ## (Welt-x, y) der Gegner

var _decor: Array[Dictionary] = []  ## nach Basis-y sortiert (hinten zuerst)
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
	var kinds := ["building", "building", "building_tall", "palm", "palm", "palm", "palm", "tank", "tank", "tank", "truck", "truck"]
	var lower_min := _ground_y + MAIN_ROAD + ROAD_THICKNESS + 8.0
	var lower_max := _ground_y + Params.val("screen", "ground_height") - 3.0
	var x := 10.0
	while x < _world_w - 10.0:
		var kind: String = kinds[rng.randi() % kinds.size()]
		var tex: Texture2D = DECOR[kind]
		var upper_min := maxf(_ground_y + tex.get_height() + 3.0, _ground_y + 20.0)
		var upper_max := _ground_y + MAIN_ROAD - 3.0
		var base: float
		if upper_min <= upper_max and not _near_pad(x, 26.0) and rng.randf() < 0.5:
			base = rng.randf_range(upper_min, upper_max)
		else:
			base = rng.randf_range(lower_min, lower_max)
		_decor.append({"tex": tex, "x": x, "base": base})
		x += rng.randf_range(18.0, 42.0)
	var truck_tex: Texture2D = DECOR["truck_black"]
	x = rng.randf_range(20.0, 80.0)
	while x < _world_w - 20.0:
		_decor.append({"tex": truck_tex, "x": x, "base": _ground_y + MAIN_ROAD + ROAD_THICKNESS})
		x += rng.randf_range(90.0, 220.0)
	_decor.sort_custom(func(a, b): return a["base"] < b["base"])


func _near_pad(x: float, margin: float) -> bool:
	var half := Params.val("world", "pad_width") * 0.5 + margin
	for p in _pads:
		if absf(Wrap.dx(x, p)) < half:
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


# --- Zeichnen -----------------------------------------------------------------

func _draw() -> void:
	var ground_h := Params.val("screen", "ground_height")
	draw_rect(Rect2(0, 0, _screen_w, _ground_y), C64.LIGHT_BLUE)
	draw_rect(Rect2(0, _ground_y, _screen_w, ground_h), C64.YELLOW)
	draw_rect(Rect2(0, _ground_y, _screen_w, 1), C64.GREY)
	_draw_roads()
	_draw_pads()
	for d in _decor:
		var sx := to_screen_x(d["x"])
		if sx > _screen_w:
			continue
		var tex: Texture2D = d["tex"]
		draw_texture(tex, Vector2(sx, d["base"] - tex.get_height()))
	_draw_hud()


func _draw_roads() -> void:
	var far_y := _ground_y + FAR_ROAD
	var main_y := _ground_y + MAIN_ROAD
	draw_rect(Rect2(0, far_y, _screen_w, ROAD_THICKNESS), C64.GREY)
	draw_rect(Rect2(0, main_y, _screen_w, ROAD_THICKNESS), C64.GREY)
	# gestrichelte Mittellinie, an die Welt gebunden
	var cam := roundi(cam_x)
	var first := -posmod(cam, 12)
	for sx in range(first, int(_screen_w), 12):
		draw_rect(Rect2(sx, main_y + 2, 6, 1), C64.WHITE)
	# Querstrassen: laufen schraeg von der hinteren zur vorderen Strasse
	var diagonals := int(_world_w / 240.0)
	for i in diagonals:
		var sx := to_screen_x(i * 240.0 + 70.0)
		if sx > _screen_w + 60.0:
			continue
		draw_line(Vector2(sx, far_y + 3), Vector2(sx - 46, main_y + 3), C64.GREY, 5.0)
		draw_line(Vector2(sx, main_y + 6), Vector2(sx - 40, _ground_y + Params.val("screen", "ground_height")), C64.GREY, 5.0)


func _draw_pads() -> void:
	var pad_w := Params.val("world", "pad_width")
	for i in _pads.size():
		var sx := to_screen_x(_pads[i] - pad_w * 0.5)
		if sx > _screen_w:
			continue
		if _pad_alive[i]:
			draw_texture(PAD_TEXTURE, Vector2(sx, _ground_y))
		else:
			draw_rect(Rect2(sx, _ground_y, pad_w, 8), C64.BLACK)
			draw_rect(Rect2(sx + 4, _ground_y + 5, 6, 3), C64.DARK_GREY)
			draw_rect(Rect2(sx + 22, _ground_y + 4, 8, 4), C64.DARK_GREY)


# --- HUD (drei Felder wie im Original) -------------------------------------------

func _panel(r: Rect2) -> void:
	draw_rect(r, C64.GREY)
	draw_rect(r, C64.DARK_GREY, false)


func _text(t: String, x: float, y: float, color: Color) -> void:
	PixelFont.draw_text(self, t, Vector2(x, y), color)


func _text_centered(t: String, cx: float, y: float, color: Color) -> void:
	_text(t, roundf(cx - PixelFont.text_width(t) * 0.5), y, color)


func _draw_hud() -> void:
	var hud_top := Params.val("screen", "hud_top")
	draw_rect(Rect2(0, hud_top, _screen_w, Params.val("screen", "height") - hud_top), C64.GREEN)
	_draw_left_panel()
	_draw_radar()
	_draw_right_panel()


func _draw_left_panel() -> void:
	_panel(Rect2(2, 168, 78, 30))
	_text("SCORE", 6, 170, C64.CYAN)
	_text("%05d" % score, 6, 177, C64.WHITE)
	_text("HI", 6, 184, C64.CYAN)
	_text("%05d" % hiscore, 6, 191, C64.LIGHT_BLUE)
	draw_texture(LIFE_ICON, Vector2(58, 172))
	_text(str(lives % 10), 63, 183, C64.BLUE)


func _draw_right_panel() -> void:
	_panel(Rect2(240, 168, 78, 30))
	_text_centered("GAS", 279, 170, C64.CYAN)
	draw_rect(Rect2(246, 177, 66, 6), C64.DARK_GREY)
	var low := fuel < Params.val("jet", "fuel_low") and (Engine.get_physics_frames() / 15) % 2 == 0
	draw_rect(Rect2(246, 177, roundf(66.0 * fuel / fuel_max), 6), C64.LIGHT_RED if low else C64.RED)
	_text_centered("AAM", 279, 185, C64.CYAN)
	_text_centered("%03d" % ammo, 279, 192, C64.YELLOW)


## Radar: auf den Spieler zentriert, zeigt die ganze Welt als Ring.
func _draw_radar() -> void:
	draw_rect(Rect2(92, 167, 136, 32), C64.GREY)
	draw_rect(Rect2(92, 167, 136, 32), C64.DARK_GREY, false)
	var win := Rect2(96, 170, 128, 16)
	draw_rect(win, C64.BLACK)
	draw_rect(Rect2(96, 186, 128, 9), C64.YELLOW)
	var half := win.size.x * 0.5
	for i in _pads.size():
		if _pad_alive[i]:
			var px := win.position.x + half + Wrap.dx(_pads[i], jet_center_x) / _world_w * win.size.x
			draw_rect(Rect2(roundf(px) - 1, win.position.y + win.size.y - 3, 3, 1), C64.WHITE)
	for e in radar_enemies:
		var px := win.position.x + half + Wrap.dx(e.x, jet_center_x) / _world_w * win.size.x
		var py := win.position.y + 1.0 + e.y / _ground_y * (win.size.y - 5.0)
		draw_rect(Rect2(roundf(px) - 1, roundf(py), 2, 2), C64.LIGHT_RED)
	draw_rect(Rect2(win.position.x + half, win.position.y, 1, win.size.y), C64.WHITE)
	_draw_speed_gauge()


## Tempoanzeige im gelben Streifen des Radars: Mitte = Stillstand, Ausschlag in
## Flugrichtung. Beim Stillstand leuchtet die Mitte gruen (Landung moeglich).
func _draw_speed_gauge() -> void:
	var box := Rect2(120, 188, 80, 5)
	var mid := box.position.x + box.size.x * 0.5
	draw_rect(box, C64.DARK_GREY, false)
	var len := jet_vx / jet_max_speed * (box.size.x * 0.5 - 2.0)
	if absf(jet_vx) < 1.0:
		draw_rect(Rect2(mid - 1, box.position.y + 1, 2, box.size.y - 2), C64.GREEN)
	else:
		draw_rect(Rect2(minf(mid, mid + len), box.position.y + 1, absf(len), box.size.y - 2), C64.BLUE)

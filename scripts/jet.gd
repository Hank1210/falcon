class_name Jet
extends Sprite2D
## Spieler-Jet: Traegheit in beiden Achsen, Treibstoff, Landen, Kamera-Vorlauf.

const FRONT_TEXTURE := preload("res://assets/sprites/jet_front.png")

var side_texture: Texture2D
var world_x := 0.0  ## linke Kante in der Welt (gewrappt)
var vx := 0.0
var vy := 0.0
var facing := 1
var screen_x := 0.0
var alive := true
var touching_ground := false
var impact_vy := 0.0  ## vertikales Tempo beim letzten Bodenkontakt
var landed := false
var locked := false  ## Start-Tanksequenz: Abheben erst nach vollem Tank
var engine_out := false
var fuel := 0.0
var ammo := 0

var _ammo_progress := 0.0
var _hold := [0.0, 0.0]  ## Einrast-Timer je Achse (x, y)
var _world_w: float
var _top: float
var _bottom: float


func _ready() -> void:
	centered = false
	scale = Vector2(Art.SCALE, Art.SCALE)
	modulate = C64.BLUE
	side_texture = texture
	_world_w = Params.val("world", "width")
	_top = Params.val("screen", "sky_top")
	_bottom = Params.val("screen", "ground_y") - Art.h(texture)
	position.y = Params.val("jet", "start_altitude")
	screen_x = Params.val("jet", "screen_x_ahead")
	fuel = Params.val("jet", "fuel_max")
	ammo = int(Params.val("jet", "ammo_max"))


## Ein Spielschritt mit fester Zeit dt (Sekunden).
func step(dt: float) -> void:
	if not alive:
		return
	var h := 0
	var v := 0
	if not engine_out:
		h = Controls.horizontal()
		v = Controls.vertical()
	if h != 0:
		facing = h
	touching_ground = false
	if landed and v < 0 and not locked:
		landed = false
		position.y -= 1.0
		vy = -10.0
	if not landed:
		_fly(dt, h, v)
	_update_camera(dt)


func _fly(dt: float, h: int, v: int) -> void:
	fuel -= Params.val("jet", "fuel_drain") * dt
	if fuel <= 0.0:
		fuel = 0.0
		engine_out = true
	var max_speed := Params.val("jet", "max_speed")
	if engine_out:
		vx = move_toward(vx, 0.0, 60.0 * dt)
		vy += Params.val("jet", "engine_out_gravity") * dt
	else:
		vx = _axis_step(0, vx, h, dt, "accel", "brake_accel", "brake_snap", max_speed)
		vx = move_toward(vx, 0.0, Params.val("jet", "drag") * dt)
		var max_vy := Params.val("jet", "max_vert_speed")
		vy = _axis_step(1, vy, v, dt, "vert_accel", "vert_brake", "vert_snap", max_vy)
	world_x = fposmod(world_x + vx * dt, _world_w)
	position.y += vy * dt
	if position.y < _top:
		position.y = _top
		vy = 0.0
	elif position.y >= _bottom:
		position.y = _bottom
		impact_vy = vy
		vy = 0.0
		touching_ground = true


func _update_camera(dt: float) -> void:
	var target := Params.val("jet", "screen_x_ahead") if facing > 0 else Params.val("jet", "screen_x_behind")
	screen_x = lerpf(screen_x, target, 1.0 - exp(-Params.val("jet", "camera_rate") * dt))
	position.x = snappedf(screen_x, 0.5)
	flip_h = facing < 0


## Beschleunigt/bremst eine Achse. Gegenschub bremst staerker als Gasgeben
## beschleunigt und rastet bei ~0 kurz ein, damit man gezielt stehen bleiben
## kann (Voraussetzung fuer die Landung).
func _axis_step(axis: int, v: float, input: int, dt: float, accel_key: String, brake_key: String, snap_key: String, max_v: float) -> float:
	if _hold[axis] > 0.0:
		_hold[axis] -= dt
		return 0.0
	if input == 0:
		return v
	var braking := v != 0.0 and signf(v) != float(input)
	if braking:
		v += input * Params.val("jet", brake_key) * dt
		if signf(v) == float(input) or absf(v) < Params.val("jet", snap_key):
			_hold[axis] = Params.val("jet", "brake_hold")
			return 0.0
		return v
	return clampf(v + input * Params.val("jet", accel_key) * dt, -max_v, max_v)


func land() -> void:
	landed = true
	engine_out = false
	vx = 0.0
	vy = 0.0
	_hold = [0.0, 0.0]
	position.y = _bottom


## Beginn eines Lebens: stehend auf einem Flugplatz, Tank und Munition leer.
func start_life(pad_center_x: float) -> void:
	alive = true
	visible = true
	engine_out = false
	world_x = fposmod(pad_center_x - Art.w(texture) * 0.5, _world_w)
	fuel = 0.0
	ammo = 0
	_ammo_progress = 0.0
	locked = true
	land()
	position.x = snappedf(screen_x, 0.5)


## Tankt und rearmiert (nur im Stand auf einem Flugplatz). Gibt true zurueck,
## wenn Tank und Munition voll sind.
func service(dt: float) -> bool:
	var fuel_max := Params.val("jet", "fuel_max")
	var ammo_max := int(Params.val("jet", "ammo_max"))
	fuel = minf(fuel + Params.val("jet", "refuel_rate") * dt, fuel_max)
	if ammo < ammo_max:
		_ammo_progress += Params.val("jet", "rearm_rate") * dt
		while _ammo_progress >= 1.0 and ammo < ammo_max:
			_ammo_progress -= 1.0
			ammo += 1
	var full := fuel >= fuel_max and ammo >= ammo_max
	if full:
		locked = false
	return full


## Frontansicht beim Landen und Schweben, Seitenansicht im Flug.
func set_front_view(on: bool) -> void:
	var wanted := FRONT_TEXTURE if on else side_texture
	if texture != wanted:
		texture = wanted


func is_front_view() -> bool:
	return texture == FRONT_TEXTURE


func center_x() -> float:
	return world_x + Art.w(texture) * 0.5


func center_y() -> float:
	return position.y + Art.h(texture) * 0.5


## Linke Kante des Bildschirms in Weltkoordinaten.
func camera_x() -> float:
	return world_x - screen_x

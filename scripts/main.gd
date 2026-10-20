extends Node2D
## Spielablauf: Jet, Raketen, Feinde, Bomben, Landen/Tanken, Wellen, Punkte.
## Game Over und Titelbild folgen in M4.

const JET_TEXTURE := preload("res://assets/sprites/jet.png")
const ENEMY_COLOR := C64.LIGHT_RED

@onready var world: World = $World
@onready var jet: Jet = $Jet

var enemies: Array[Enemy] = []
var missiles: Array[Missile] = []
var debris: Array[Debris] = []
var explosions: Array[Explosion] = []

var score := 0
var lives := 0
var wave := 0  ## Nummer der aktuellen/naechsten Welle (0 = erste)
var wave_kills := 0
var wave_time := 0.0
var wave_active := false
var wave_pause_left := 0.0
var respawn_left := 0.0
var invulnerable_left := 0.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = int(Params.val("world", "seed"))
	lives = int(Params.val("score", "start_lives"))
	world.restore_pads()
	jet.start_life(world.pad_center(0))
	wave_pause_left = Params.val("enemy", "first_wave_delay")
	if OS.get_cmdline_user_args().has("--selftest"):
		_selftest()


func _physics_process(delta: float) -> void:
	_step(delta)


func _step(dt: float) -> void:
	if jet.alive:
		jet.step(dt)
		if Controls.fire_pressed():
			_try_fire()
		_check_jet_ground()
		if jet.alive and jet.landed:
			jet.service(dt)
	elif respawn_left > 0.0:
		respawn_left -= dt
		if respawn_left <= 0.0:
			_respawn_jet()
	invulnerable_left = maxf(invulnerable_left - dt, 0.0)

	_step_missiles(dt)
	var pads := world.alive_pad_centers()
	for e in enemies:
		e.step(dt, jet.world_x, jet.position.y, pads, _rng)
		_maybe_bomb(e)
	_step_debris(dt)
	_check_hits()
	_step_explosions(dt)
	_step_wave(dt)
	_update_view()


# --- Waffen ---------------------------------------------------------------

func _try_fire() -> bool:
	if jet.ammo <= 0 or missiles.size() >= int(Params.val("jet", "max_missiles")):
		return false
	var m := Missile.new()
	var dir := jet.facing
	m.vx = dir * Params.val("jet", "missile_speed")
	m.life = Params.val("jet", "missile_life")
	m.world_x = jet.world_x + (JET_TEXTURE.get_width() if dir > 0 else -Missile.WIDTH)
	m.position.y = jet.position.y + 3.0
	add_child(m)
	missiles.append(m)
	jet.ammo -= 1
	return true


func _step_missiles(dt: float) -> void:
	for m in missiles.duplicate():
		if not m.step(dt):
			missiles.erase(m)
			m.queue_free()


## Gegner werfen Bomben so, dass sie (mit Vorhalt) auf einen intakten
## Flugplatz oder den Spieler fallen.
func _maybe_bomb(e: Enemy) -> void:
	if e.leaving or e.bomb_cooldown > 0.0:
		return
	var g := Params.val("enemy", "bomb_gravity")
	var speed := Params.val("enemy", "speed")
	var from_y := e.position.y + 6.0
	var fall := Params.val("screen", "ground_y") - from_y
	var drop := false
	if fall > 12.0:
		var t := sqrt(2.0 * fall / g)
		drop = world.pad_index_at(e.center_x() + e.dir * speed * t + e.aim_error, 6.0) >= 0
	if not drop and jet.alive:
		var fall_jet := jet.center_y() - from_y
		if fall_jet > 12.0:
			var tj := sqrt(2.0 * fall_jet / g)
			var impact := e.center_x() + e.dir * speed * tj + e.aim_error
			drop = absf(Wrap.dx(impact, jet.center_x() + jet.vx * tj)) < 6.0
	if not drop:
		return
	e.bomb_cooldown = Params.val("enemy", "bomb_cooldown")
	e.aim_error = _rng.randf_range(-1.0, 1.0) * Params.val("enemy", "bomb_aim_error")
	var b := Debris.new()
	b.kind = Debris.Kind.BOMB
	b.world_x = e.center_x() - 1.0
	b.position.y = from_y
	b.vx = e.dir * speed
	add_child(b)
	debris.append(b)


func _step_debris(dt: float) -> void:
	var ground := Params.val("screen", "ground_y")
	for d in debris.duplicate():
		d.step(dt)
		if d.bottom_y() >= ground:
			var pad := world.pad_index_at(d.center_x())
			if pad >= 0:
				world.destroy_pad(pad)
				_explode(world.pad_center(pad), ground - 3.0, true)
			else:
				_explode(d.center_x(), ground - 2.0, false)
			debris.erase(d)
			d.queue_free()
		elif d.kind == Debris.Kind.BOMB and jet.alive and invulnerable_left <= 0.0 \
				and _overlap(d.center_x(), d.center_y(), d.width(), d.height(), jet.center_x(), jet.center_y(), JET_TEXTURE.get_width(), JET_TEXTURE.get_height()):
			_explode(d.center_x(), d.center_y(), false)
			debris.erase(d)
			d.queue_free()
			_crash_jet()
			break


# --- Kollisionen ------------------------------------------------------------

func _overlap(ax: float, ay: float, aw: float, ah: float, bx: float, by: float, bw: float, bh: float) -> bool:
	return absf(Wrap.dx(ax, bx)) < (aw + bw) * 0.5 and absf(ay - by) < (ah + bh) * 0.5


func _check_hits() -> void:
	var ew := float(JET_TEXTURE.get_width())
	var eh := float(JET_TEXTURE.get_height())
	for m in missiles.duplicate():
		for e in enemies.duplicate():
			if _overlap(m.center_x(), m.position.y + 0.5, Missile.WIDTH, Missile.HEIGHT, e.center_x(), e.center_y(), ew, eh):
				missiles.erase(m)
				m.queue_free()
				_kill_enemy(e, true)
				break
	if jet.alive and invulnerable_left <= 0.0:
		for e in enemies.duplicate():
			if _overlap(jet.center_x(), jet.center_y(), ew, eh, e.center_x(), e.center_y(), ew, eh):
				_kill_enemy(e, false)
				_crash_jet()
				break


## Bodenkontakt: nur sanft und im Stand ueber einem intakten Flugplatz ist
## das eine Landung, sonst ein Absturz.
func _check_jet_ground() -> void:
	if not jet.touching_ground:
		return
	var pad := world.pad_index_at(jet.center_x())
	var ok := pad >= 0 and absf(jet.vx) <= Params.val("jet", "land_max_speed") \
		and jet.impact_vy <= Params.val("jet", "land_max_vy")
	if ok:
		jet.land()
	else:
		_crash_jet()


func _kill_enemy(e: Enemy, by_missile: bool) -> void:
	enemies.erase(e)
	_explode(e.center_x(), e.center_y(), false)
	if by_missile:
		var w := Debris.new()
		w.kind = Debris.Kind.WRECK
		w.world_x = e.world_x
		w.position.y = e.position.y
		w.vx = e.dir * Params.val("enemy", "speed") * 0.6
		add_child(w)
		debris.append(w)
		var table := Params.arr("score", "points")
		score += int(Params.val("score", "points_last")) if enemies.is_empty() else int(table[mini(wave_kills, table.size() - 1)])
		wave_kills += 1
	e.queue_free()


func _crash_jet() -> void:
	_explode(jet.center_x(), jet.center_y(), true)
	jet.alive = false
	jet.visible = false
	lives -= 1
	respawn_left = Params.val("jet", "respawn_time")
	_clear_hostiles()


func _clear_hostiles() -> void:
	for node in enemies + missiles + debris:
		node.queue_free()
	enemies.clear()
	missiles.clear()
	debris.clear()
	wave_active = false
	wave_pause_left = Params.val("enemy", "first_wave_delay")


## Neues Leben: alle Flugplaetze sind wieder intakt, der Jet steht leer auf dem
## naechstgelegenen und muss tanken (Abheben erst bei vollem Tank).
func _respawn_jet() -> void:
	if lives <= 0:
		# Platzhalter bis M4 (Game Over): von vorn beginnen
		lives = int(Params.val("score", "start_lives"))
		score = 0
		wave = 0
	world.restore_pads()
	jet.start_life(world.pad_center(world.nearest_pad(jet.world_x)))
	invulnerable_left = 0.0


# --- Wellen -----------------------------------------------------------------

func _wave_size(n: int) -> int:
	return mini(2 + floori(float(n) / Params.val("enemy", "waves_per_step")), int(Params.val("enemy", "max_wave_size")))


func _wave_pause(n: int) -> float:
	return maxf(Params.val("enemy", "wave_pause_min"), Params.val("enemy", "wave_pause_start") - Params.val("enemy", "wave_pause_step") * n)


func _spawn_wave() -> void:
	wave_active = true
	wave_time = 0.0
	wave_kills = 0
	var dist := Params.val("enemy", "spawn_distance")
	for i in _wave_size(wave):
		var side := 1 if i % 2 == 0 else -1
		var wx := fposmod(jet.world_x + side * (dist + i * 80.0), Params.val("world", "width"))
		var y := _rng.randf_range(Params.val("screen", "sky_top") + 10.0, Params.val("screen", "ground_y") - 40.0)
		_spawn_enemy(wx, y, -side)


func _spawn_enemy(wx: float, y: float, dir: int) -> Enemy:
	var e := Enemy.new()
	e.texture = JET_TEXTURE
	e.modulate = ENEMY_COLOR
	e.world_x = wx
	e.dir = dir
	e.target_y = y
	e.position.y = y
	e.aim_error = _rng.randf_range(-1.0, 1.0) * Params.val("enemy", "bomb_aim_error")
	add_child(e)
	enemies.append(e)
	return e


func _step_wave(dt: float) -> void:
	if enemies.is_empty():
		if wave_active:
			wave_active = false
			wave += 1
			wave_pause_left = _wave_pause(wave)
		elif wave_pause_left > 0.0 and jet.alive:
			wave_pause_left -= dt
			if wave_pause_left <= 0.0:
				_spawn_wave()
		return
	wave_time += dt
	if wave_time > Params.val("enemy", "wave_timeout"):
		for e in enemies:
			e.leaving = true
	for e in enemies.duplicate():
		if e.leaving and absf(Wrap.dx(e.world_x, jet.world_x)) > Params.val("enemy", "leave_distance"):
			enemies.erase(e)
			e.queue_free()


# --- Effekte und Darstellung --------------------------------------------------

func _explode(wx: float, wy: float, big: bool) -> void:
	var x := Explosion.new()
	x.setup(wx, wy, big)
	add_child(x)
	explosions.append(x)


func _step_explosions(dt: float) -> void:
	for x in explosions.duplicate():
		if not x.step(dt):
			explosions.erase(x)
			x.queue_free()


func _place(node: Node2D, wx: float) -> void:
	var sx := world.to_screen_x(wx)
	node.position.x = sx
	node.visible = sx > -40.0 and sx < Params.val("screen", "width") + 40.0


func _update_view() -> void:
	world.cam_x = jet.camera_x()
	world.jet_world_x = jet.world_x
	world.jet_vx = jet.vx
	world.jet_max_speed = Params.val("jet", "max_speed")
	world.score = score
	world.lives = maxi(lives, 0)
	world.ammo = jet.ammo
	world.ammo_max = int(Params.val("jet", "ammo_max"))
	world.fuel = jet.fuel
	world.fuel_max = Params.val("jet", "fuel_max")
	world.radar_enemies.clear()
	for e in enemies:
		world.radar_enemies.append(e.center_x())
	world.queue_redraw()
	for e in enemies:
		_place(e, e.world_x)
	for m in missiles:
		_place(m, m.world_x)
	for d in debris:
		_place(d, d.world_x)
	for x in explosions:
		_place(x, x.world_x)
		x.position.y = x.world_y


# --- Selbsttest (godot --headless --path . -- --selftest) -----------------------

func _selftest() -> void:
	var failures: Array[String] = []
	var check := func(ok: bool, what: String) -> void:
		if not ok:
			failures.append(what)
	var run := func(seconds: float) -> void:
		for i in int(seconds * 60.0):
			_step(1.0 / 60.0)
	var fuel_max := Params.val("jet", "fuel_max")
	var ground := Params.val("screen", "ground_y")
	wave_pause_left = 1.0e9  # Wellen nur auf Anforderung

	# Start: gelandet, leer, gesperrt
	check.call(world.alive_pad_count() == 6, "Start: 6 Flugplaetze")
	check.call(jet.landed and jet.locked and jet.fuel == 0.0 and jet.ammo == 0, "Start: gelandet, Tank und Munition leer, gesperrt")
	run.call(11.0)
	check.call(jet.fuel >= fuel_max and jet.ammo == int(Params.val("jet", "ammo_max")) and not jet.locked, "Tanken und Aufmunitionieren fuellt alles und gibt Abflug frei")

	# Wellengroesse und Pausen
	check.call(_wave_size(0) == 2 and _wave_size(5) == 2 and _wave_size(6) == 3 and _wave_size(12) == 4 and _wave_size(40) == 4, "Wellengroesse 2/3/4")
	check.call(_wave_pause(1) > _wave_pause(10) and _wave_pause(100) == Params.val("enemy", "wave_pause_min"), "Pausen werden kuerzer, mit Untergrenze")

	# Raketenabschuss, letzter Gegner der Welle gibt 200
	var base_wave := wave
	_spawn_wave()
	check.call(enemies.size() == _wave_size(base_wave), "Welle spawnt")
	for e in enemies.duplicate():
		enemies.erase(e)
		e.queue_free()
	jet.landed = false
	jet.position.y = 60.0
	var target := _spawn_enemy(jet.world_x + 90.0, jet.position.y - 2.0, 1)
	target.target_y = target.position.y
	check.call(_try_fire(), "Jet darf feuern")
	run.call(1.0)
	check.call(enemies.is_empty() and score == int(Params.val("score", "points_last")), "Rakete trifft, letzter Gegner gibt %d Punkte (ist %d)" % [Params.val("score", "points_last"), score])
	check.call(wave == base_wave + 1 and wave_pause_left > 0.0, "Welle vorbei: naechste Welle plus Pause")
	check.call(debris.size() >= 1 and debris[0].kind == Debris.Kind.WRECK, "Abgeschossener Gegner faellt als Wrack")
	run.call(3.0)

	# Treibstoff: Verbrauch, Motorausfall, Absturz, Flugplaetze erneuert
	wave_pause_left = 1.0e9
	jet.alive = true
	jet.visible = true
	jet.landed = false
	jet.engine_out = false
	jet.position.y = 100.0
	jet.vx = 0.0
	jet.vy = 0.0
	jet.fuel = 50.0
	run.call(1.0)
	check.call(jet.fuel < 50.0 - 1.0, "Treibstoff sinkt im Flug")
	world.destroy_pad(3)
	var lives_before := lives
	jet.fuel = 0.01
	run.call(0.1)
	check.call(jet.engine_out, "Leerer Tank: Motorausfall")
	run.call(2.0)
	check.call(not jet.alive and lives == lives_before - 1, "Motorausfall endet im Absturz")
	run.call(Params.val("jet", "respawn_time") + 0.2)
	check.call(jet.alive and jet.landed and jet.locked and world.alive_pad_count() == 6, "Neues Leben: gelandet, gesperrt, Flugplaetze erneuert")

	# Landung auf intaktem Flugplatz
	jet.locked = false
	jet.landed = false
	jet.fuel = 50.0
	jet.world_x = world.pad_center(1) - 8.0
	jet.position.y = 1000.0
	jet.vx = 0.0
	jet.vy = 20.0
	_step(1.0 / 60.0)
	check.call(jet.alive and jet.landed, "Sanfte Landung im Stand auf Flugplatz")

	# Zu schnelle Landung: Absturz
	jet.landed = false
	jet.world_x = world.pad_center(1) - 8.0
	jet.position.y = 1000.0
	jet.vx = 0.0
	jet.vy = 120.0
	lives_before = lives
	_step(1.0 / 60.0)
	check.call(not jet.alive and lives == lives_before - 1, "Zu hohes Sinktempo = Absturz")
	run.call(Params.val("jet", "respawn_time") + 0.2)

	# Landung auf zerstoertem Flugplatz: Absturz
	var jet_pad := world.nearest_pad(jet.world_x)
	var other := (jet_pad + 2) % 6
	world.destroy_pad(other)
	jet.landed = false
	jet.fuel = 50.0
	jet.world_x = world.pad_center(other) - 8.0
	jet.position.y = 1000.0
	jet.vx = 0.0
	jet.vy = 10.0
	lives_before = lives
	_step(1.0 / 60.0)
	check.call(not jet.alive and lives == lives_before - 1, "Zerstoerter Flugplatz taugt nicht zum Landen")
	run.call(Params.val("jet", "respawn_time") + 0.2)

	# Bombe zerstoert Flugplatz, Wrack ebenso
	jet_pad = world.nearest_pad(jet.world_x)
	var p1 := (jet_pad + 3) % 6
	var p2 := (jet_pad + 4) % 6
	var bomb := Debris.new()
	bomb.world_x = world.pad_center(p1)
	bomb.position.y = ground - 6.0
	add_child(bomb)
	debris.append(bomb)
	var wreck := Debris.new()
	wreck.kind = Debris.Kind.WRECK
	wreck.world_x = world.pad_center(p2) - 8.0
	wreck.position.y = ground - 8.0
	add_child(wreck)
	debris.append(wreck)
	run.call(0.5)
	check.call(not world.pad_alive(p1), "Bombe zerstoert Flugplatz")
	check.call(not world.pad_alive(p2), "Abstuerzendes Wrack zerstoert Flugplatz")

	# Gegner zielt: wirft Bombe mit Vorhalt auf intakten Flugplatz
	var p3 := (jet_pad + 2) % 6
	world.restore_pads()
	var attacker := _spawn_enemy(0.0, 40.0, 1)
	attacker.hunting_jet = false
	attacker.aim_error = 0.0
	attacker.pad_anchor_x = world.pad_center(p3)
	var fall := ground - (attacker.position.y + 6.0)
	var lead := Params.val("enemy", "speed") * sqrt(2.0 * fall / Params.val("enemy", "bomb_gravity"))
	attacker.world_x = fposmod(world.pad_center(p3) - lead - 8.0, Params.val("world", "width"))
	var before := debris.size()
	_maybe_bomb(attacker)
	check.call(debris.size() == before + 1, "Gegner wirft Bombe, wenn sie den Flugplatz trifft")
	run.call(2.0)
	check.call(not world.pad_alive(p3), "Bombe mit Vorhalt trifft den Flugplatz")

	# Bombe trifft den (stehenden) Jet
	invulnerable_left = 0.0
	var b2 := Debris.new()
	b2.world_x = jet.center_x() - 1.0
	b2.position.y = jet.position.y - 2.0
	add_child(b2)
	debris.append(b2)
	lives_before = lives
	_step(1.0 / 60.0)
	check.call(not jet.alive and lives == lives_before - 1, "Bombe trifft Jet")

	if failures.is_empty():
		print("SELFTEST OK")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("SELFTEST FEHLER: ", f)
		get_tree().quit(1)

class_name Controls
## Tastatureingabe. Mit dem Benutzerargument "--autoplay" laeuft ein
## festes Testskript statt der Tastatur (fuer Screenshots und Tests).

static var _autoplay := OS.get_cmdline_user_args().has("--autoplay")


static func _seconds() -> float:
	return Engine.get_physics_frames() / 60.0


## -1 = links, +1 = rechts
static func horizontal() -> int:
	if _autoplay:
		var t := _seconds()
		if t < 3.0:
			return 1
		if t < 6.0:
			return -1
		return 0
	return int(Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_LEFT))


## -1 = steigen, +1 = sinken (Bildschirmkoordinaten)
static func vertical() -> int:
	if _autoplay:
		var t := _seconds()
		if t >= 1.0 and t < 1.6:
			return -1
		if t >= 2.0 and t < 2.6:
			return 1
		return 0
	return int(Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_UP))


static var _fire_was_down := false


static func autoplay() -> bool:
	return _autoplay


## Wahr nur im Frame, in dem Feuer gedrueckt wird (keine Dauerfeuer-Wiederholung).
static func fire_pressed() -> bool:
	var down: bool
	if _autoplay:
		var f := Engine.get_physics_frames()
		down = f > 30 and f % 40 < 3
	else:
		down = Input.is_physical_key_pressed(KEY_SPACE)
	var pressed := down and not _fire_was_down
	_fire_was_down = down
	return pressed

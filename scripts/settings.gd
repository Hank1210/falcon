class_name Settings
## Persistente Optionen in user://settings.json.

static var path := "user://settings.json"
static var skip_refuel := false  ## Start-Tanksequenz ueberspringen (Original: nicht moeglich)
static var crt := false  ## Scanlines


static func load_all() -> void:
	skip_refuel = false
	crt = false
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
		if data is Dictionary:
			skip_refuel = bool(data.get("skip_refuel", false))
			crt = bool(data.get("crt", false))


static func save() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"skip_refuel": skip_refuel, "crt": crt}))

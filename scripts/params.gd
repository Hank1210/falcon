class_name Params
## Liest die Gameplay-Werte aus res://data/params.json.

const PATH := "res://data/params.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var file := FileAccess.open(PATH, FileAccess.READ)
		_data = JSON.parse_string(file.get_as_text())
	return _data


static func val(section: String, key: String) -> float:
	return float(data()[section][key])


static func arr(section: String, key: String) -> Array:
	return data()[section][key]

class_name Highscores
## Lokale Bestenliste (Top 5) in user://highscores.json.

const MAX_ENTRIES := 5
const NAME_LENGTH := 3

static var path := "user://highscores.json"
static var entries: Array[Dictionary] = []  ## [{name, score}], absteigend sortiert


static func load_all() -> void:
	entries = []
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
		if data is Array:
			for e in data:
				if e is Dictionary and e.has("name") and e.has("score"):
					entries.append({"name": str(e["name"]), "score": int(e["score"])})
	_sort()


static func save() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entries))


static func best() -> int:
	return int(entries[0]["score"]) if not entries.is_empty() else 0


static func qualifies(score: int) -> bool:
	return score > 0 and (entries.size() < MAX_ENTRIES or score > int(entries[-1]["score"]))


static func add(player_name: String, score: int) -> void:
	entries.append({"name": player_name, "score": score})
	_sort()
	entries.resize(mini(entries.size(), MAX_ENTRIES))
	save()


static func _sort() -> void:
	entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))

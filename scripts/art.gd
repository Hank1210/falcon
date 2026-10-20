class_name Art
## Die Sprites sind mit doppelter Pixeldichte gezeichnet und werden mit SCALE
## verkleinert dargestellt. Alle Spielkoordinaten und Groessen bleiben in
## "logischen" Pixeln (320x200); diese Hilfen rechnen Texturgroessen dorthin um.

const SCALE := 0.5


static func size(tex: Texture2D) -> Vector2:
	return tex.get_size() * SCALE


static func w(tex: Texture2D) -> float:
	return tex.get_width() * SCALE


static func h(tex: Texture2D) -> float:
	return tex.get_height() * SCALE

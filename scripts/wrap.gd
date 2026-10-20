class_name Wrap
## Abstaende in der sich wiederholenden Welt.


## Kuerzeste vorzeichenbehaftete Distanz von b nach a ("a minus b") auf dem Weltring.
static func dx(a: float, b: float) -> float:
	var w := Params.val("world", "width")
	return fposmod(a - b + w * 0.5, w) - w * 0.5

@tool
extends CanvasItem

## Declarative drawing attached by `xo ui draw`. Edit recipe_json to change the drawing.
@export_multiline var recipe_json: String = "":
	set(value):
		recipe_json = value
		_ops = null
		queue_redraw()

var _ops = null

func _color(v, fallback := Color.WHITE) -> Color:
	if v is String:
		return Color.html(v)
	if v is Array and v.size() >= 3:
		return Color(v[0], v[1], v[2], v[3] if v.size() > 3 else 1.0)
	return fallback

func _points(v) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in v:
		out.append(Vector2(p[0], p[1]))
	return out

func _draw() -> void:
	if _ops == null:
		var parsed = JSON.parse_string(recipe_json) if recipe_json != "" else []
		_ops = parsed if parsed is Array else []
	for op in _ops:
		if not op is Dictionary:
			continue
		var color := _color(op.get("color"))
		var width: float = op.get("width", -1.0)
		var filled: bool = op.get("filled", true)
		if op.has("line"):
			var pts := _points(op["line"])
			if pts.size() >= 2:
				draw_line(pts[0], pts[1], color, width, op.get("antialiased", false))
		elif op.has("rect"):
			var r = op["rect"]
			if r is Array and r.size() >= 4:
				draw_rect(Rect2(r[0], r[1], r[2], r[3]), color, filled, width)
		elif op.has("circle"):
			var c = op["circle"]
			if c is Array and c.size() >= 3:
				draw_circle(Vector2(c[0], c[1]), c[2], color, filled, width)
		elif op.has("arc"):
			var a = op["arc"]
			if a is Array and a.size() >= 5:
				draw_arc(Vector2(a[0], a[1]), a[2], deg_to_rad(a[3]), deg_to_rad(a[4]), op.get("points", 32), color, width if width > 0 else 1.0, op.get("antialiased", false))
		elif op.has("polyline"):
			draw_polyline(_points(op["polyline"]), color, width if width > 0 else 1.0, op.get("antialiased", false))
		elif op.has("polygon"):
			draw_colored_polygon(_points(op["polygon"]), color)
		elif op.has("string"):
			var s = op["string"]
			var at = s.get("at", [0, 16])
			draw_string(ThemeDB.fallback_font, Vector2(at[0], at[1]), str(s.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, s.get("size", 16), color)

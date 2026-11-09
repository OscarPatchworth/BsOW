# menu_backdrop.gd
class_name MenuBackdrop
extends Control

## The menus' background: a dark field of hex outlines drifting slowly, with a few hexes filled
## in biome colours, like landers scattered across the board.

const HEX_SIZE: float = 46.0
const DRIFT := Vector2(9.0, 4.0)
const BIOME_COLORS: Array[Color] = [
	Color(0.5, 0.29, 0.25),   # badlands
	Color(0.18, 0.37, 0.16),  # forest
	Color(0.36, 0.30, 0.42),  # mountain
	Color(0.62, 0.56, 0.30),  # plains
]

var _time: float = 0.0
## Grid cell -> colour, for the filled hexes.
var _filled := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		_filled[Vector2i(rng.randi_range(-4, 40), rng.randi_range(-4, 26))] = BIOME_COLORS[rng.randi() % BIOME_COLORS.size()]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.06, 0.08))
	# Pointy-top hexes: columns sqrt(3) * size apart, rows 1.5 * size apart, odd rows shifted.
	var column_step := sqrt(3.0) * HEX_SIZE
	var row_step := 1.5 * HEX_SIZE
	var offset := Vector2(fposmod(_time * DRIFT.x, column_step), fposmod(_time * DRIFT.y, row_step * 2.0))
	var shift := Vector2i(floori(_time * DRIFT.x / column_step), floori(_time * DRIFT.y / (row_step * 2.0)) * 2)
	for row in range(-2, int(size.y / row_step) + 3):
		for column in range(-2, int(size.x / column_step) + 3):
			var centre := Vector2(column * column_step + (column_step * 0.5 if row % 2 != 0 else 0.0), row * row_step) + offset
			var points := _hex_points(centre, HEX_SIZE * 0.94)
			var cell := Vector2i(column - shift.x, row - shift.y)
			if _filled.has(cell):
				var pulse := 0.3 + 0.08 * sin(_time * 0.8 + cell.x * 1.7 + cell.y)
				draw_colored_polygon(points, Color(_filled[cell], pulse))
			points.append(points[0])
			draw_polyline(points, Color(1, 1, 1, 0.045), 1.5)
	# Darken towards the edges so the panels stand out.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25))


static func _hex_points(centre: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in 6:
		var angle := deg_to_rad(60.0 * k - 90.0)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return points

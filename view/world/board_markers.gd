# board_markers.gd
class_name BoardMarkers
extends Node3D

## Lasting markers on the board, drawn for the local player:
##   show_selection()  a bright pulsing hex ring on the selected lander (the one in the inspector).
##   add_arrow()       a thick arrow from one lander to another in an actor's colour, with an
##                     optional label over the target: battles (kept until the battle ends) and
##                     other players' moves (fade after a few seconds).
## Arrows follow their landers, so they stay right while gravity moves things.

## White, so it never looks like a player colour (owner rings use those).
const SELECTION_COLOR := Color(1.0, 1.0, 1.0)
const ARROW_HEIGHT: float = 1.25
const ARROW_WIDTH: float = 0.22
const FADE_SECONDS: float = 0.6

var _selection_ring: MeshInstance3D
var _selection_material := StandardMaterial3D.new()
var _selected: Lander
var _time: float = 0.0
var _arrows_mesh := ImmediateMesh.new()
var _arrows: MeshInstance3D
## Key -> {from: Lander, to: Lander, color: Color, label: Label3D, expires: float (-1 = until removed)}
var _active := {}


func _ready() -> void:
	_selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_selection_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_selection_material.no_depth_test = true
	_selection_material.albedo_color = SELECTION_COLOR
	_selection_ring = MeshInstance3D.new()
	_selection_ring.mesh = Hex.ring_mesh(Hex.RADIUS * 0.98, Hex.RADIUS * 1.24, _selection_material)
	_selection_ring.visible = false
	add_child(_selection_ring)

	var arrow_material := StandardMaterial3D.new()
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_material.vertex_color_use_as_albedo = true
	arrow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_material.no_depth_test = true
	arrow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_arrows = MeshInstance3D.new()
	_arrows.mesh = _arrows_mesh
	_arrows.material_override = arrow_material
	add_child(_arrows)


func _process(delta: float) -> void:
	_time += delta
	if _selected != null and is_instance_valid(_selected):
		_selection_ring.position = _selected.get_board_position() + Vector3.UP * (_selected.position.y + 0.99)
		_selection_material.albedo_color = Color(SELECTION_COLOR, 0.55 + 0.45 * sin(_time * 5.0))
		_selection_ring.visible = true
	else:
		_selection_ring.visible = false
	_draw_arrows()


#region Public API
## Rings `lander` as the current selection (null clears it).
func show_selection(lander: Lander) -> void:
	_selected = lander


func get_selection() -> Lander:
	return _selected


## Draws an arrow `from` -> `to` under `key` (replacing one with the same key). `seconds` < 0
## keeps it until remove_arrow(key).
func add_arrow(key: Variant, from: Lander, to: Lander, color: Color, label_text: String = "", seconds: float = -1.0) -> void:
	remove_arrow(key)
	var label: Label3D = null
	if label_text != "":
		label = Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.fixed_size = true
		label.pixel_size = 0.0009
		label.font_size = 34
		label.outline_size = 12
		label.outline_modulate = Color(0, 0, 0, 0.9)
		label.modulate = color.lightened(0.35)
		label.render_priority = 20
		label.text = label_text
		add_child(label)
	_active[key] = {"from": from, "to": to, "color": color, "label": label,
		"expires": _time + seconds if seconds >= 0.0 else -1.0}


func remove_arrow(key: Variant) -> void:
	if not _active.has(key):
		return
	var label: Label3D = _active[key]["label"]
	if label != null:
		label.queue_free()
	_active.erase(key)


func has_arrow(key: Variant) -> bool:
	return _active.has(key)


func get_arrow_count() -> int:
	return _active.size()
#endregion


#region Private
func _draw_arrows() -> void:
	_arrows_mesh.clear_surfaces()
	var drew := false
	for key in _active.keys():
		var arrow: Dictionary = _active[key]
		var from: Lander = arrow["from"]
		var to: Lander = arrow["to"]
		var expires: float = arrow["expires"]
		if not is_instance_valid(from) or not is_instance_valid(to) or (expires >= 0.0 and _time > expires):
			remove_arrow(key)
			continue
		var alpha := 1.0
		if expires >= 0.0:
			alpha = clampf((expires - _time) / FADE_SECONDS, 0.0, 1.0)
		var pulse := 0.8 + 0.2 * sin(_time * 6.0) if expires < 0.0 else 1.0
		var color: Color = arrow["color"]
		if not drew:
			_arrows_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			drew = true
		_add_arrow(from.get_board_position(), to.get_board_position(), Color(color.lightened(0.15), alpha * pulse))
		var label: Label3D = arrow["label"]
		if label != null:
			label.position = to.get_board_position() + Vector3.UP * 2.0
			label.modulate.a = alpha
	if drew:
		_arrows_mesh.surface_end()


func _add_arrow(from: Vector3, to: Vector3, color: Color) -> void:
	var a := from + Vector3.UP * ARROW_HEIGHT
	var b := to + Vector3.UP * ARROW_HEIGHT
	var direction := b - a
	if direction.length() < 0.1:
		return
	var forward := direction.normalized()
	# Start and stop a little inside each lander so the head sits on the target.
	a += forward * 0.45
	b -= forward * 0.35
	var head_base := b - forward * 0.55
	var side := forward.cross(Vector3.UP).normalized()
	var w := side * ARROW_WIDTH * 0.5
	for vertex in [a - w, a + w, head_base + w, a - w, head_base + w, head_base - w]:
		_arrows_mesh.surface_set_color(color)
		_arrows_mesh.surface_add_vertex(vertex)
	for vertex in [head_base - side * ARROW_WIDTH * 1.4, head_base + side * ARROW_WIDTH * 1.4, b]:
		_arrows_mesh.surface_set_color(color)
		_arrows_mesh.surface_add_vertex(vertex)
#endregion

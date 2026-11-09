# placement_preview.gd
class_name PlacementPreview
extends Node3D

## World-space hints drawn by the PlayerController. Everything is built once and updated in
## place (no meshes created per frame), so previews don't stutter.
##
##   show_placement()  ghost lander at the cursor, where gravity will pull it, the landers that
##                     pull on it (brighter = stronger), and which landers it will connect to.
##   show_drag()       a ribbon from a lander to the cursor or target while moving/attacking.
##   show_hover()      a ring around the lander under the cursor.

const VALID_COLOR := Color(0.35, 0.95, 0.55)
const INVALID_COLOR := Color(1.0, 0.3, 0.3)
const PULL_COLOR := Color(0.75, 0.85, 1.0)
const CONNECT_COLOR := Color(1.0, 1.0, 1.0)
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.8)
const LINE_HEIGHT: float = 1.0
const RIBBON_WIDTH: float = 0.09

var _ghost: MeshInstance3D
var _ghost_material := StandardMaterial3D.new()
var _settle_marker: MeshInstance3D
var _settle_material := StandardMaterial3D.new()
var _connect_ring: MeshInstance3D
var _hover_ring: MeshInstance3D
var _lines: MeshInstance3D
var _lines_mesh := ImmediateMesh.new()
var _lines_material := StandardMaterial3D.new()
var _connection_distance: float = 2.5
var _caption: Label3D


func _ready() -> void:
	_ghost = _make_disc(Hex.RADIUS, 0.1, _ghost_material, 0.45)
	_settle_marker = _make_ring(Hex.RADIUS * 0.86, Hex.RADIUS * 1.0, _settle_material)
	_connect_ring = _make_ring(_connect_ring_radius() - 0.05, _connect_ring_radius() + 0.05, _make_flat_material(Color(1, 1, 1, 0.35)))
	_hover_ring = _make_ring(Hex.RADIUS * 1.02, Hex.RADIUS * 1.12, _make_flat_material(HOVER_COLOR))
	_caption = Label3D.new()
	_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_caption.no_depth_test = true
	_caption.fixed_size = true
	_caption.pixel_size = 0.0008
	_caption.font_size = 30
	_caption.outline_size = 12
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_caption.outline_modulate = Color(0, 0, 0, 0.85)
	_caption.render_priority = 10
	add_child(_caption)

	_lines_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lines_material.vertex_color_use_as_albedo = true
	_lines_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lines_material.no_depth_test = true
	_lines_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_lines = MeshInstance3D.new()
	_lines.mesh = _lines_mesh
	_lines.material_override = _lines_material
	add_child(_lines)
	hide_all()


#region Public API
## The ring around the ghost shows this range (landers inside it will be connected).
func set_connection_distance(distance: float) -> void:
	_connection_distance = distance
	if _connect_ring != null:
		var material := _connect_ring.mesh.surface_get_material(0)
		_connect_ring.mesh = Hex.ring_mesh(_connect_ring_radius() - 0.05, _connect_ring_radius() + 0.05, material)


## `pulls` maps Lander -> pull strength (0..1). `connects` are landers it would connect to.
## `caption` is shown above the ghost (e.g. which biome is about to land); `problem` is why
## it can't land there, shown under the caption when it's invalid.
func show_placement(spot: Vector3, is_valid: bool, settle_spot: Vector3, pulls: Dictionary,
		connects: Array[Lander], tint: Color = Color.TRANSPARENT, caption: String = "",
		problem: String = "Can't place a lander here") -> void:
	var color := VALID_COLOR if is_valid else INVALID_COLOR
	if is_valid and tint.a > 0.0:
		color = tint
	_ghost_material.albedo_color = Color(color, 0.45)
	_ghost.position = _flat(spot) + Vector3.UP * 0.9
	_ghost.visible = true
	_caption.text = caption if is_valid else (caption + "\n" if caption != "" else "") + problem
	_caption.modulate = Color(tint, 1.0).lightened(0.6) if is_valid and tint.a > 0.0 else Color(color, 1.0)
	_caption.position = _flat(spot) + Vector3.UP * 2.3
	_caption.visible = _caption.text != ""

	var will_move := is_valid and _flat(settle_spot).distance_to(_flat(spot)) > 0.15
	_settle_material.albedo_color = Color(color, 0.9)
	_settle_marker.position = _flat(settle_spot) + Vector3.UP * 0.95
	_settle_marker.visible = will_move
	_connect_ring.position = _flat(settle_spot if is_valid else spot) + Vector3.UP * 0.92
	_connect_ring.visible = true

	_lines_mesh.clear_surfaces()
	_lines_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_geometry := false
	if is_valid:
		for lander: Lander in pulls:
			var strength: float = pulls[lander]
			_add_ribbon(spot, lander.get_board_position(), RIBBON_WIDTH * (0.5 + strength), Color(PULL_COLOR, 0.15 + 0.6 * strength))
			has_geometry = true
		for lander in connects:
			_add_ribbon(settle_spot, lander.get_board_position(), RIBBON_WIDTH * 0.6, Color(CONNECT_COLOR, 0.9))
			has_geometry = true
		if will_move:
			_add_ribbon(spot, settle_spot, RIBBON_WIDTH, Color(color, 0.9))
			has_geometry = true
	_end_lines(has_geometry)


## A ribbon from `from` to `to`, e.g. while dragging units between landers.
func show_drag(from: Vector3, to: Vector3, color: Color) -> void:
	_ghost.visible = false
	_caption.visible = false
	_settle_marker.visible = false
	_connect_ring.visible = false
	_lines_mesh.clear_surfaces()
	_lines_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_ribbon(from, to, RIBBON_WIDTH * 1.6, color)
	_add_arrow_head(from, to, color)
	_end_lines(true)


func show_hover(lander: Lander, color: Color = HOVER_COLOR) -> void:
	if lander == null:
		_hover_ring.visible = false
		return
	(_hover_ring.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color = color
	_hover_ring.position = lander.get_board_position() + Vector3.UP * (lander.position.y + 0.93)
	_hover_ring.visible = true


func hide_placement() -> void:
	_ghost.visible = false
	_caption.visible = false
	_settle_marker.visible = false
	_connect_ring.visible = false
	_lines.visible = false


func hide_all() -> void:
	hide_placement()
	_hover_ring.visible = false
#endregion


#region Private
func _add_ribbon(from: Vector3, to: Vector3, width: float, color: Color) -> void:
	var a := _flat(from) + Vector3.UP * LINE_HEIGHT
	var b := _flat(to) + Vector3.UP * LINE_HEIGHT
	var direction := b - a
	if direction.length() < 0.01:
		return
	var side := direction.cross(Vector3.UP).normalized() * width * 0.5
	for vertex in [a - side, a + side, b + side, a - side, b + side, b - side]:
		_lines_mesh.surface_set_color(color)
		_lines_mesh.surface_add_vertex(vertex)


func _add_arrow_head(from: Vector3, to: Vector3, color: Color) -> void:
	var tip := _flat(to) + Vector3.UP * LINE_HEIGHT
	var direction := (_flat(to) - _flat(from))
	if direction.length() < 0.3:
		return
	direction = direction.normalized()
	var side := direction.cross(Vector3.UP) * 0.3
	var back := tip - direction * 0.5
	for vertex in [tip, back + side, back - side]:
		_lines_mesh.surface_set_color(color)
		_lines_mesh.surface_add_vertex(vertex)


func _end_lines(has_geometry: bool) -> void:
	if has_geometry:
		_lines_mesh.surface_end()
	else:
		_lines_mesh.clear_surfaces()  # An empty surface can't be ended.
	_lines.visible = has_geometry


func _make_disc(radius: float, height: float, material: StandardMaterial3D, alpha: float) -> MeshInstance3D:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(VALID_COLOR, alpha)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.85
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	add_child(instance)
	return instance


## A flat hexagonal outline (corner radii `inner`..`outer`), lined up with the landers.
func _make_ring(inner: float, outer: float, material: StandardMaterial3D) -> MeshInstance3D:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	var instance := MeshInstance3D.new()
	instance.mesh = Hex.ring_mesh(inner, outer, material)
	add_child(instance)
	return instance


## Lander centres inside this hex (corner radius) are within connection range of the ghost.
func _connect_ring_radius() -> float:
	return _connection_distance * 2.0 / sqrt(3.0)


func _make_flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func _flat(point: Vector3) -> Vector3:
	return Vector3(point.x, 0, point.z)
#endregion

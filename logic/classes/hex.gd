# hex.gd
class_name Hex
extends RefCounted

## Hexagon geometry shared by landers, gravity and previews. Every lander is the same regular
## hexagon, pointy along +Z (the way Godot's 6-sided CylinderMesh is built), and landers never
## rotate, so all hexes on the board line up.
##
## Hex distance (`distance`) is the face-to-face measure between two hex centres: two hexes
## sitting flat face to face are exactly 2 × APOTHEM apart, and two hexes overlap exactly when
## their hex distance is less than that. Spacing and connection rules use it.

## Centre to the middle of a face. Face to face, two landers are 2 × APOTHEM apart.
const APOTHEM: float = 1.0
## Centre to a corner.
const RADIUS: float = APOTHEM * 2.0 / sqrt(3.0)

## Outward face normals (flat on the board), at 30° + 60°·k from +Z.
static var _normals: Array[Vector3] = _make_normals()


static func _make_normals() -> Array[Vector3]:
	var normals: Array[Vector3] = []
	for k in 6:
		var angle := deg_to_rad(30.0 + 60.0 * k)
		normals.append(Vector3(sin(angle), 0, cos(angle)))
	return normals


## Face-to-face distance between hex centres `a` and `b` (height ignored).
static func distance(a: Vector3, b: Vector3) -> float:
	var offset := Vector3(b.x - a.x, 0, b.z - a.z)
	var most := 0.0
	for k in 3:  # The other three normals are these, negated.
		most = maxf(most, absf(offset.dot(_normals[k])))
	return most


## The six spots where a hex sits face to face with one at `centre`.
static func neighbour_slots(centre: Vector3) -> Array[Vector3]:
	var slots: Array[Vector3] = []
	for normal in _normals:
		slots.append(Vector3(centre.x, 0, centre.z) + normal * APOTHEM * 2.0)
	return slots


## The six corners (flat, around the origin) of a hex with corner radius `radius`.
static func corners(radius: float = RADIUS) -> PackedVector3Array:
	var points := PackedVector3Array()
	for k in 6:
		var angle := deg_to_rad(60.0 * k)
		points.append(Vector3(sin(angle), 0, cos(angle)) * radius)
	return points


## A flat hexagonal outline between corner radii `inner` and `outer`, facing up.
static func ring_mesh(inner: float, outer: float, material: Material = null) -> ArrayMesh:
	var inner_corners := corners(inner)
	var outer_corners := corners(outer)
	var vertices := PackedVector3Array()
	for k in 6:
		var next := (k + 1) % 6
		vertices.append_array([inner_corners[k], outer_corners[k], outer_corners[next],
			inner_corners[k], outer_corners[next], inner_corners[next]])
	return _mesh_from(vertices, material)


## A filled flat hexagon with corner radius `radius`, facing up.
static func disc_mesh(radius: float, material: Material = null) -> ArrayMesh:
	var points := corners(radius)
	var vertices := PackedVector3Array()
	for k in 6:
		vertices.append_array([Vector3.ZERO, points[k], points[(k + 1) % 6]])
	return _mesh_from(vertices, material)


static func _mesh_from(vertices: PackedVector3Array, material: Material) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material != null:
		mesh.surface_set_material(0, material)
	return mesh

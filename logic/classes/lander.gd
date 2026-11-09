# lander.gd
class_name Lander
extends RigidBody3D

## A tile on the board. Holds a biome, at most one building, and a group of units.
## Changes are announced through ActionManager.action_resolved, not by the lander itself.
##
## Landers are physics bodies: they drop in when placed, the GravitySystem pulls them together,
## and they can crash into each other (crashed_into). Game rules only use the flat board
## position (get_board_position), so height never affects spacing or connections.

## This lander hit another one. Emitted on both landers; `impact_speed` is their closing speed.
signal crashed_into(other: Lander, impact_speed: float)

const DEFAULT_UNIT_CAPACITY: int = 5
const UNIT_RING_RADIUS: float = 0.55
## Slows landers down so a gravity pull settles instead of sliding forever.
const LINEAR_DAMP: float = 2.5
const NEUTRAL_COLOR := Color(0.55, 0.55, 0.6)

@export var biome_mesh: CSGMesh3D

var _biome_data: BiomeData
var _building: BuildingInstance
var _units: Array[UnitInstance] = []
var _unit_capacity: int = DEFAULT_UNIT_CAPACITY

var _owner_ring: MeshInstance3D
var _owner_ring_material := StandardMaterial3D.new()
var _info_label: Label3D
var _flash_tween: Tween

@onready var _building_node: Node3D = find_child("Building")
@onready var _units_node: Node3D = find_child("Units")


func _ready() -> void:
	collision_mask |= LanderManager.WALL_LAYER
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	linear_damp = LINEAR_DAMP
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_build_markers()
	_refresh_unit_meshes()
	refresh_markers()


#region Public API
## Builds `action`'s building (building_data, or the purchasable) for the action's actor.
func build(action: Action) -> void:
	var building_data: BuildingData = action.get_building_data()
	if building_data == null:
		building_data = action.get_purchasable() as BuildingData
	if building_data == null:
		push_warning("Lander | build() called without a BuildingData")
		return

	build_for(building_data, action.get_actor())


## Puts a new `building_data` building owned by `owner_actor` on this lander.
func build_for(building_data: BuildingData, owner_actor: Actor) -> void:
	var building := BuildingInstance.new(building_data, owner_actor)
	building.bind_mesh_parent(_building_node)
	set_building(building)
	building.refresh_mesh()


## Spawns `action`'s unit (unit_data, or the purchasable) for the action's actor.
func buy_unit(action: Action) -> void:
	var unit_data: UnitData = action.get_unit_data()
	if unit_data == null:
		unit_data = action.get_purchasable() as UnitData
	if unit_data == null:
		push_warning("Lander | buy_unit() called without a UnitData")
		return

	add_units([UnitInstance.new(unit_data, action.get_actor())] as Array[UnitInstance])


## Removes the building (razed). Its mesh goes with it.
func remove_building() -> void:
	if get_building() == null:
		return
	get_building().bind_mesh_parent(null)
	for child in _building_node.get_children():
		child.queue_free()
	set_building(null)


func add_units(new_units: Array[UnitInstance]) -> void:
	var units := get_units().duplicate()
	for unit in new_units:
		if unit in units:
			push_warning("Lander | Unit is already on this lander")
			continue
		units.append(unit)
	set_units(units)


func remove_units(units_to_remove: Array[UnitInstance]) -> void:
	var units := get_units().duplicate()
	for unit in units_to_remove:
		if unit not in units:
			push_warning("Lander | Unit is not on this lander")
			continue
		units.erase(unit)
	set_units(units)


func has_building() -> bool:
	return get_building() != null


func has_units() -> bool:
	return not get_units().is_empty()


func is_full() -> bool:
	return get_units().size() >= get_unit_capacity()


## Where the lander sits on the board, ignoring height. Use this for every distance rule.
func get_board_position() -> Vector3:
	return Vector3(position.x, 0, position.z)  # The Landers root sits at the origin.


## Everything `actor` could buy on this lander right now: building upgrades, units the building
## can spawn (only unit types it trains), and buildings the units here can build (only units with
## can_build, and only `actor`'s own units).
func get_purchasables(actor: Actor) -> Array[Resource]:
	var purchasables: Array[Resource] = []
	var building := get_building()

	if building != null:
		purchasables.append_array(building.get_upgrades())
		var spawnable_types := building.get_spawnable_unit_types()
		for unit_data in actor.get_species().get_units():
			if unit_data.get_unit_type() in spawnable_types:
				purchasables.append(unit_data)
	else:
		for unit in get_units():
			if unit.get_owner_actor() != actor or not unit.can_build_buildings():
				continue
			for building_data in unit.get_buildables():
				if building_data not in purchasables:
					purchasables.append(building_data)

	return AbilitySystem.resolve_get(self, &"purchasables", purchasables)


## Redraws the owner ring and the info label. Called whenever the owner might have changed.
func refresh_markers() -> void:
	if _owner_ring == null:
		return
	var owner_actor := get_owner_actor()
	_owner_ring_material.albedo_color = owner_actor.get_color() if owner_actor != null else NEUTRAL_COLOR
	_owner_ring.visible = owner_actor != null

	var lines: Array[String] = []
	if has_units():
		lines.append("%d" % get_units().size())
	if owner_actor != null:
		lines.append(owner_actor.get_display_name())
	_info_label.text = "\n".join(lines)
	_info_label.modulate = owner_actor.get_color() if owner_actor != null else NEUTRAL_COLOR


## Briefly pulses the owner ring, e.g. to show what the AI just did.
func flash(color: Color) -> void:
	if _owner_ring == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	_owner_ring.visible = true
	_owner_ring_material.emission_enabled = true
	_owner_ring_material.emission = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_owner_ring_material, "emission_energy_multiplier", 3.0, 0.15).from(0.0)
	_flash_tween.tween_property(_owner_ring_material, "emission_energy_multiplier", 0.0, 0.6)
	_flash_tween.tween_callback(func() -> void:
		_owner_ring_material.emission_enabled = false
		refresh_markers())
#endregion


#region Accessors
func get_biome_data() -> BiomeData:
	return AbilitySystem.resolve_get(self, &"biome_data", _biome_data)


func set_biome_data(value: BiomeData) -> void:
	_biome_data = AbilitySystem.resolve_set(self, &"biome_data", _biome_data, value)
	_refresh_biome_mesh()


func get_building() -> BuildingInstance:
	return AbilitySystem.resolve_get(self, &"building", _building)


func set_building(value: BuildingInstance) -> void:
	_building = AbilitySystem.resolve_set(self, &"building", _building, value)
	refresh_markers()


func get_units() -> Array[UnitInstance]:
	return AbilitySystem.resolve_get(self, &"units", _units)


func set_units(value: Array[UnitInstance]) -> void:
	_units = AbilitySystem.resolve_set(self, &"units", _units, value)
	_refresh_unit_meshes()
	refresh_markers()


func get_unit_capacity() -> int:
	return AbilitySystem.resolve_get(self, &"unit_capacity", _unit_capacity)


func set_unit_capacity(value: int) -> void:
	_unit_capacity = AbilitySystem.resolve_set(self, &"unit_capacity", _unit_capacity, value)


## The building's owner if there is a building, otherwise the owner of the units, otherwise null.
func get_owner_actor() -> Actor:
	var owner_actor: Actor = null
	if get_building() != null:
		owner_actor = get_building().get_owner_actor()
	elif has_units():
		owner_actor = get_units()[0].get_owner_actor()
	return AbilitySystem.resolve_get(self, &"owner_actor", owner_actor)


func get_upkeep() -> EconData:
	return AbilitySystem.resolve_get(self, &"upkeep", get_biome_data().get_upkeep())
#endregion


#region Signal handlers
func _on_body_entered(body: Node) -> void:
	var other := body as Lander
	if other == null:
		return
	crashed_into.emit(other, (linear_velocity - other.linear_velocity).length())
#endregion


#region Private
func _refresh_biome_mesh() -> void:
	biome_mesh.material = get_biome_data().get_mesh_material()


## Units stand in an even ring (one unit stands in the middle), so the layout doesn't jump around.
func _refresh_unit_meshes() -> void:
	if _units_node == null:
		return  # Not in the tree yet, so there is nothing to draw into.
	for child in _units_node.get_children():
		child.queue_free()
	var units := get_units()
	for i in units.size():
		var unit_mesh: Node3D = units[i].get_mesh_scene().instantiate()
		if units.size() > 1:
			var angle := TAU * i / units.size()
			unit_mesh.position += Vector3(cos(angle), 0, sin(angle)) * UNIT_RING_RADIUS
		_units_node.add_child(unit_mesh)


func _build_markers() -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.98
	ring_mesh.outer_radius = 1.12
	ring_mesh.rings = 48
	ring_mesh.ring_segments = 6
	_owner_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mesh.material = _owner_ring_material
	_owner_ring = MeshInstance3D.new()
	_owner_ring.name = "OwnerRing"
	_owner_ring.mesh = ring_mesh
	_owner_ring.position = Vector3(0, 0.95, 0)
	_owner_ring.scale = Vector3(1, 0.35, 1)
	add_child(_owner_ring)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.no_depth_test = true
	_info_label.fixed_size = true
	_info_label.pixel_size = 0.0007
	_info_label.font_size = 28
	_info_label.outline_size = 10
	_info_label.position = Vector3(0, 2.4, 0)
	add_child(_info_label)
#endregion

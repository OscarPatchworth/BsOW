# building_data.gd
extends Resource
class_name BuildingData  

@export var name: String
#@export var cost: EconData 
@export var build_mesh: PackedScene
@export var build_icon: CompressedTexture2D
@export var unique_build = false
@export var override_unit_capacity = false
@export var unit_capacity = -1
@export var can_spawn = false
@export var spawn_type: Array[UnitData.UnitType]


## Get/Set (er)s
# Name
func get_building_name() -> String:
	return name

# Cost
#func get_econ() -> EconData:
#	return cost

# Mesh
func get_mesh() -> PackedScene:
	return build_mesh

# Icon
func get_icon() -> CompressedTexture2D:
	return build_icon

# Unit Capacity Override
func get_capacity_override() -> bool:
	return override_unit_capacity

# Unit capacity
func get_unit_capacity() -> int:
	return unit_capacity

# Can spawn
func get_can_spawn() -> bool:
	return can_spawn

# Spawn Types
func get_spawn_type() -> Array:
	return spawn_type

# All
func get_building_dict() -> Dictionary:
	var all = {
		"name": name,
		#"cost" : cost,
		"mesh" : build_mesh,
		"icon" : build_icon,
		"capacity_override" : override_unit_capacity,
		"unit_capacity" : unit_capacity,
		"can_spawn" : can_spawn,
		"spawn_types" : spawn_type
	}
	return all

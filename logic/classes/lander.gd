class_name Lander
extends Node3D

signal built_action_completed(req: Action)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables

# @export variables
@export var biome_mesh: Node3D

# remaining regular variables
var has_building: bool = false
var has_units: bool = false
var biome_data: BiomeData
var building: BuildingData

# @onready variables
@onready var building_node: Node3D = self.find_child("Building")

###################################################################################################
###	Methods
func update_biome():
	biome_mesh.set_material(biome_data.mesh_material)


## Get/Set (er)s
func get_biome() -> BiomeData:
	return biome_data
func set_biome(new_biome: BiomeData):
	biome_data = new_biome
	update_biome()


func get_building() -> BuildingData:
	if(building == null) :
		print("Calling for NULL building on Lander!!")
	return building

### Calls
func build_action(req: Action):
	var build_mesh = req.get_building_type().build_mesh.instantiate()
	building_node.add_child(build_mesh)
	building = req.get_building_type()
	has_building = true
	built_action_completed.emit(req)

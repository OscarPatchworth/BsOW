class_name Lander
extends Node3D

#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables

# @export variables
@export var biome_mesh: Node3D

# remaining regular variables
var has_building: bool = false
var biome_data: BiomeData

# @onready variables


###################################################################################################
###	Methods
func get_biome() -> BiomeData:
	return biome_data
func set_biome(new_biome: BiomeData):
	biome_data = new_biome
	update_biome()


func update_biome():
	biome_mesh.set_material(biome_data.mesh_material)

#biome_data.gd
class_name BiomeData
extends Resource

@export var name: String
@export var mesh_material: Material
@export var poker_icon: CompressedTexture2D
@export var upkeep_econ: EconData


###################################################################################################
###	Methods
func get_upkeep_econ():
	return upkeep_econ

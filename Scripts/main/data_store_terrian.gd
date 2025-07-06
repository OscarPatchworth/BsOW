extends Node

###		BIOMES DATA		###

# signals

# enums
#BIOME TYPES
enum BiomeType {BADLANDS, COAST, FOREST, MOUNT, OCEAN, PLAINS, PLASMA}

# constants
#Biome Material Links
# C:/Users/Kyran/Documents/GamerGirlBathWater/bsow/Textures/Materials/terrian_materials/
const BADLANDS_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Badlands.tres"
const COAST_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Coast.tres"
const FOREST_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Forest.tres"
const MOUNT_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Mount.tres"
const OCEAN_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Ocean.tres"
const PLAINS_MATERIAL ="res://Textures/Materials/terrian_materials/Terrian_Plains.tres"
const PLASMA_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Plasma.tres"
#Biome Texture Links
# C:/Users/Kyran/Documents/GamerGirlBathWater/bsow/Textures/Materials/UI_Textures/Panel/
const BADLANDS_STYLEBOX = "res://Textures/UI_Textures/Panel/BadlandQueue.tres"
const COAST_STYLEBOX = "res://Textures/UI_Textures/Panel/CoastQueue.tres"
const FOREST_STYLEBOX = "res://Textures/UI_Textures/Panel/ForesetQueue.tres"
const MOUNT_STYLEBOX = "res://Textures/UI_Textures/Panel/Mount.tres"
const OCEAN_STYLEBOX = "res://Textures/UI_Textures/Panel/OceanQueue.tres"
const PLAINS_STYLEBOX = "res://Textures/UI_Textures/Panel/PlainsQueue.tres"
const PLASMA_STLEBOX = "res://Textures/UI_Textures/Panel/PlasmaQueue.tres"

# static variables
var next_biome: BiomeType
var queued_biome: BiomeType
# @export variables

# remaining regular variables

# @onready variables
#Biome UI Queue
@onready var UIscript = $"../../UI/NextBiomeDisplay/Panel"

###################################################################################################
###	Methods

### Standard Methods

### Custom Mehtods
func updatequeued_biomes() -> void:
	next_biome = queued_biome
	queued_biome = BiomeType.values().pick_random()

func rand_queded_biomes() -> void:
	next_biome = BiomeType.values().pick_random()
	queued_biome = BiomeType.values().pick_random()

###	Connected signals
func _on_user_controler_biome_placed() -> void:
	updatequeued_biomes()
	UIscript.updated_biome_queue(next_biome, queued_biome)
	pass # Replace with function body.

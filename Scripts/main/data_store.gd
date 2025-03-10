extends Node3D

#BIOME TYPES
enum biomeType {Badlands, Coast, Forest, Mount, Ocean, Plains, Plasma}
#Biome Material Links
const BADLANDS_MATERIAL = "res://Terrian/Biomes/Materials/Terrian_Badlands.tres"
const COAST_MATERIAL = "res://Terrian/Biomes/Materials/Terrian_Coast.tres"
const FOREST_MATERIAL = "res://Terrian/Biomes/Materials/Terrian_Forest.tres"
const MOUNT_MATERIAL = "res://Terrian/Biomes/Materials/Terrian_Mount.tres"
const OCEAN_MATERIAL = "res://Terrian/Biomes/Materials/Terrian_Ocean.tres"
const PLAINS_MATERIAL ="res://Terrian/Biomes/Materials/Terrian_Plains.tres"
const PLASMA_MATERIAL = "res://Terrian/Biomes/Materials/Terrian_Plasma.tres"
#Biome Texture Links
const BADLANDS_STYLEBOX = "res://Terrian/Biomes/UI_Textures/BadlandQueue.tres"
const COAST_STYLEBOX = "res://Terrian/Biomes/UI_Textures/CoastQueue.tres"
const FOREST_STYLEBOX = "res://Terrian/Biomes/UI_Textures/ForesetQueue.tres"
const MOUNT_STYLEBOX = "res://Terrian/Biomes/UI_Textures/Mount.tres"
const OCEAN_STYLEBOX = "res://Terrian/Biomes/UI_Textures/OceanQueue.tres"
const PLAINS_STYLEBOX = "res://Terrian/Biomes/UI_Textures/PlainsQueue.tres"
const PLASMA_STLEBOX = "res://Terrian/Biomes/UI_Textures/PlasmaQueue.tres"


#Biome UI Queue
var nextbiome: biomeType
var queuedbiome: biomeType

@onready var UIscript = $"../../UI/Control/Panel"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_user_controler_biome_placed() -> void:
	nextbiome = queuedbiome
	queuedbiome = biomeType.values().pick_random()
	UIscript.updated_biome_queue(nextbiome, queuedbiome)
	pass # Replace with function body.

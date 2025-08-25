extends Node

###		BIOMES DATA		###

# signals

# enums
#BIOME TYPES
enum BiomeType {NONE, BADLANDS, COAST, FOREST, MOUNT, OCEAN, PLAINS, PLASMA}

# constants
### Biome Material Links
# C:/Users/Kyran/Documents/GamerGirlBathWater/bsow/Textures/Materials/terrian_materials/
const BADLANDS_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Badlands.tres"
const COAST_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Coast.tres"
const FOREST_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Forest.tres"
const MOUNT_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Mount.tres"
const OCEAN_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Ocean.tres"
const PLAINS_MATERIAL ="res://Textures/Materials/terrian_materials/Terrian_Plains.tres"
const PLASMA_MATERIAL = "res://Textures/Materials/terrian_materials/Terrian_Plasma.tres"

### Biome Texture Links
# C:/Users/Kyran/Documents/GamerGirlBathWater/bsow/Textures/Materials/UI_Textures/Panel/
const BADLANDS_STYLEBOX = "res://Textures/UI_Textures/Panel/BadlandQueue.tres"
const COAST_STYLEBOX = "res://Textures/UI_Textures/Panel/CoastQueue.tres"
const FOREST_STYLEBOX = "res://Textures/UI_Textures/Panel/ForesetQueue.tres"
const MOUNT_STYLEBOX = "res://Textures/UI_Textures/Panel/Mount.tres"
const OCEAN_STYLEBOX = "res://Textures/UI_Textures/Panel/OceanQueue.tres"
const PLAINS_STYLEBOX = "res://Textures/UI_Textures/Panel/PlainsQueue.tres"
const PLASMA_STLEBOX = "res://Textures/UI_Textures/Panel/PlasmaQueue.tres"

### Biome btn THEAMEs
# C:/Users/Kyran/Documents/GamerGirlBathWater/bsow/Textures/Theames/Buttons/plains_btn_terrian_start.tres
const BADLANDS_BTN_THEAME = "res://Textures/Theames/Buttons/badlands_btn_terrian_start.tres"
const COAST_BTN_THEAME = "res://Textures/Theames/Buttons/coast_btn_terrian_start.tres"
const FOREST_BTN_THEAME = "res://Textures/Theames/Buttons/forest_btn_terrian_start.tres"
const MOUNT_BTN_THEAME = "res://Textures/Theames/Buttons/mount_btn_terrian_start.tres"
const OCEAN_BTN_THEAME = "res://Textures/Theames/Buttons/ocean_btn_terrian_start.tres"
const PLAINS_BTN_THEAME = "res://Textures/Theames/Buttons/plains_btn_terrian_start.tres"
const PLASMA_BTN_THEAME = "res://Textures/Theames/Buttons/plasma_btn_terrian_start.tres"

### BiomeRes(s)
const BADLANDS_BIOME_RES = "res://Scripts/Resources/biome/biome_badlands.tres"
const COAST_BIOME_RES = "res://Scripts/Resources/biome/biome_coast.tres"
const FOREST_BIOME_RES = "res://Scripts/Resources/biome/biome_forest.tres"
const MOUNT_BIOME_RES = "res://Scripts/Resources/biome/biome_mount.tres"
const OCEAN_BIOME_RES = "res://Scripts/Resources/biome/biome_ocean.tres"
const PLAINS_BIOME_RES = "res://Scripts/Resources/biome/biome_plains.tres"
const PLASMA_BIOME_RES = "res://Scripts/Resources/biome/biome_plasma.tres"


###	Building Packed Sence Links
const BUILDING_HQ_PACKED_SENCE = "res://Assest_Scenes/buildings/build_HQ.tscn"
const BUILDING_TOWER_PACKED_SENCE = "res://Assest_Scenes/buildings/build_outpost.tscn"


# static variables
var next_biome: BiomeType
var queued_biome: BiomeType

var building_HQ: PackedScene
var building_Tower

var ui_script: Node
# @export variables

# remaining regular variables

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")

###################################################################################################
###	Methods

### Standard Methods

func _ready() -> void:
	ui_script = get_node("/" + data_node_ref.UI_BIOME_DISPLAY + "/Panel")
	building_HQ = load(BUILDING_HQ_PACKED_SENCE)
	building_Tower = load(BUILDING_TOWER_PACKED_SENCE)


### Custom Mehtods
func updatequeued_biomes() -> void:
	next_biome = queued_biome
	
	if queued_biome != 0:
		var rnd = randi_range(1, BiomeType.size()-1)
		queued_biome = rnd as BiomeType


func rand_queded_biomes() -> void:
	var rnd = randi_range(1, BiomeType.size()-1)
	next_biome = rnd as BiomeType
	
	rnd = randi_range(1, BiomeType.size()-1)
	queued_biome = rnd as BiomeType

func set_active_biome(biome_type: int) -> void:
	next_biome = biome_type as BiomeType


func get_biome_material(biome: int) -> String:
	match biome:
		BiomeType.PLASMA:
			return(PLASMA_MATERIAL)
		BiomeType.BADLANDS:
			return(BADLANDS_MATERIAL)
		BiomeType.COAST:
			return(COAST_MATERIAL)
		BiomeType.FOREST:	
			return(FOREST_MATERIAL)
		BiomeType.MOUNT:
			return(MOUNT_MATERIAL)
		BiomeType.OCEAN:
			return(OCEAN_MATERIAL)
		BiomeType.PLAINS:
			return(PLAINS_MATERIAL)
		_:
			return("")

		
func get_biome_btn_theame(biome: int) -> String:
	match biome:
		BiomeType.PLASMA:
			return(PLASMA_BTN_THEAME)
		BiomeType.BADLANDS:
			return(BADLANDS_BTN_THEAME)
		BiomeType.COAST:
			return(COAST_BTN_THEAME)
		BiomeType.FOREST:	
			return(FOREST_BTN_THEAME)
		BiomeType.MOUNT:
			return(MOUNT_BTN_THEAME)
		BiomeType.OCEAN:
			return(OCEAN_BTN_THEAME)
		BiomeType.PLAINS:
			return(PLAINS_BTN_THEAME)
		_:
			return("")

func get_biome_res(biome: int) -> String:
	match biome:
		BiomeType.PLASMA:
			return(PLASMA_BIOME_RES)
		BiomeType.BADLANDS:
			return(BADLANDS_BIOME_RES)
		BiomeType.COAST:
			return(COAST_BIOME_RES)
		BiomeType.FOREST:	
			return(FOREST_BIOME_RES)
		BiomeType.MOUNT:
			return(MOUNT_BIOME_RES)
		BiomeType.OCEAN:
			return(OCEAN_BIOME_RES)
		BiomeType.PLAINS:
			return(PLAINS_BIOME_RES)
		_:
			return("")


### Code from ChatGPT
func get_enum_key(enum_dict: Dictionary, target_value) -> String:
	for key in enum_dict.keys():
		if enum_dict[key] == target_value:
			return key
	return "UNKNOWN"  # or null if you prefer


###	Connected signals
func _on_user_controler_biome_placed(player_state, spawn_spot: Dictionary) -> void:
	updatequeued_biomes()
	ui_script.updated_biome_queue(next_biome, queued_biome)
	pass # Replace with function body.

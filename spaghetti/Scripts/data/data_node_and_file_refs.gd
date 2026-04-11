extends Node

# signals

# enums

# constants
### DATA
const DATA_TERRIAN = "root/Node3D/Data/DataStoreTerrian"
const DATA_SETTINGS = "root/Node3D/Data/SettingsData"
const GRAVITY_NODE = "root/Node3D/Data/Gravity"
const GAME_MASTER = "root/Node3D/Data/Game_Master"
const DATA_NODE_REFS = "root/Node3D/Data/DataNodeRefs"

### UI
const UI_BIOME_DISPLAY = "root/Node3D/UI/NextBiomeDisplay"
const UI_BIOMES_START = "root/Node3D/UI/StarterBiomeDisplay"
const UI_PLAYER_RESOURCES = "root/Node3D/UI/Active_Player_Resources"
const UI_TERRIAN_INFO = "/root/Node3D/UI/Terrian_Info_Panel/Panel"

### Player
const PLAYERS = "/root/Node3D/Players"
const DATA_PLAYER = "/root/Node3D/Data/DataStorePlayer"

### Scripts
const class_btn_terrian_select = "res://Scripts/classes/buttons/btn_terrian_select.gd"
const CLASS_PLAYER = "res://Scripts/classes/self_player/self_player.gd"
const CLASS_BUILDING = "res://Scripts/classes/building/building.gd"
const CLASS_UNIT = "res://Scripts/classes/unit/unit.gd"
const BTN_CONNECTED_LANDER = "res://Scripts/classes/buttons/btn_connected_lander.gd"
const BASIC_AI_SCRIPT = "res://Scripts/classes/self_player/basic_ai.gd"

### Tree Hiracies
const terrian_node_folder = "root/Node3D/World_Objects/Terrian"

### Resources
# Buildings
const BUILDING_TOWER = "res://Scripts/Resources/building/building_tower.tres"
const BUILDING_HQ = "res://Scripts/Resources/building/building_hq.tres"

# Misc
const LANDER_COLLISION_A3D = "res://Assest_Scenes/Player/is_placeable_box.tscn"
### Sences


# static variables

# @export variables

# remaining regular variables

# @onready variables


###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods


### Connected Signals

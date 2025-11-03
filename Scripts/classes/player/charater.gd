class_name character
extends Node3D

# signals

# enums

# constants

# static variables
var data_node_ref
var game_master
var data_player
var race: RaceRes
var lander_collision_a3d

# @export variables

# remaining regular variables
var player_resources = CostRes.new()

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_signals()

	player_resources.gold = 3000

	lander_collision_a3d = load(data_node_ref.LANDER_COLLISION_A3D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func init_race(ply_race: String):
	race = load(ply_race)


func generate_biome_resources() -> void:
	if (randi()):
		player_resources.food += 100
	
	if (randi()):
		player_resources.mineral += 100

### Connected Signals
func connect_signals() -> void:
	data_node_ref = get_node("/root/Node3D/Data/DataNodeRefs")
	game_master = get_node("/" + data_node_ref.GAME_MASTER)
	data_player = get_node("/" + data_node_ref.DATA_PLAYER)

	game_master.players_generate_biome_resources.connect(self.generate_biome_resources)

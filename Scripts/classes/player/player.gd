class_name player
extends Node

# signals
signal update_ui_food(food: int)
signal update_ui_mineral(mineral: int)

# enums

# constants

# static variables
var data_node_ref
var game_master
var data_player
var race: RaceRes

# @export variables

# remaining regular variables
var player_resources = CostRes.new()

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	data_node_ref = get_node("/root/Node3D/Data/DataNodeRefs")
	game_master = get_node("/" + data_node_ref.GAME_MASTER)
	data_player = get_node("/" + data_node_ref.DATA_PLAYER)

	connect_signals()

	race = load(data_player.rnd_race())

	player_resources.gold = 3000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func generate_biome_resources() -> void:
	if (randi() % 2):
		player_resources.food += 1
	
	if (randi() % 2):
		player_resources.mineral += 1

	update_ui_food.emit(player_resources.food)
	update_ui_mineral.emit(player_resources.mineral)

### Connected Signals
func connect_signals() -> void:
	game_master.players_generate_biome_resources.connect(self.generate_biome_resources)

	var ui_resource_display = get_node("/" + data_node_ref.UI_PLAYER_RESOURCES)
	self.update_ui_food.connect(ui_resource_display.update_food)
	self.update_ui_mineral.connect(ui_resource_display.update_mineral)

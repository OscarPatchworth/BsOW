class_name player
extends character

# signals
signal update_ui_food(food: int)
signal update_ui_mineral(mineral: int)

# enums

# constants

# static variables

# @export variables

# remaining regular variables


# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_signals()
	init_race(data_player.rnd_race())

	player_resources.gold = 3000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func generate_biome_resources() -> void:
	if (randi()):
		player_resources.food += 100
	
	if (randi()):
		player_resources.mineral += 100

	update_ui_food.emit(player_resources.food)
	update_ui_mineral.emit(player_resources.mineral)

### Connected Signals
func connect_signals() -> void:
	data_node_ref = get_node("/root/Node3D/Data/DataNodeRefs")
	game_master = get_node("/" + data_node_ref.GAME_MASTER)
	data_player = get_node("/" + data_node_ref.DATA_PLAYER)

	game_master.players_generate_biome_resources.connect(self.generate_biome_resources)

	var ui_resource_display = get_node("/" + data_node_ref.UI_PLAYER_RESOURCES)
	self.update_ui_food.connect(ui_resource_display.update_food)
	self.update_ui_mineral.connect(ui_resource_display.update_mineral)

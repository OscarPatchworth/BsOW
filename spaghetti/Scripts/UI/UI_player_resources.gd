extends Control

# signals

# enums

# constants

# static variables
var data_node_ref
var game_master

var food_control
var mineral_control

# @export variables

# remaining regular variables
var active_player

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_signals()

	food_control = get_child(0).get_child(1)
	mineral_control = get_child(1).get_child(1)


	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func update_active_player(self_player: Node) -> void:
	active_player = self_player

func update_food(food: int) -> void:
	food_control.set_text("  " + str(food))


func update_mineral(mineral: int) -> void:
	mineral_control.set_text("  " + str(mineral))

### Connected Signals]
func connect_signals() -> void:
	data_node_ref = get_node("/root/Node3D/Data/DataNodeRefs")
	game_master = get_node("/" + data_node_ref.GAME_MASTER)

	game_master.update_active_player.connect(self.update_active_player)
	pass

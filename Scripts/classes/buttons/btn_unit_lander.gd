class_name BtnUnitLander # Class Name
extends Node


# signals

# enums

# constants

# static variables
var unit_res: UnitRes
var game_master
var data_node_ref


# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#ready_signals()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func set_unit_data(unit: Unit):
	self.icon = unit.unit_res.icon

### Connected Signals
func ready_signals():
	data_node_ref = get_node("%DataNodeRefs")
	game_master = get_node("/" + data_node_ref.GAME_MASTER)

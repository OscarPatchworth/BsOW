class_name BtnUnitLander # Class Name
extends Button


# signals
signal unit_selected()
signal unit_unselected()
# enums

# constants

# static variables
var unit_res: UnitRes
var game_master
var data_node_ref


# @export variables

# remaining regular variables
var is_toggled : bool

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
func _init() -> void:
	### init btn func
	set_toggle_mode(true)
	set_action_mode(ACTION_MODE_BUTTON_RELEASE)
	is_toggled = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#ready_signals()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _toggled(toggled_on: bool) -> void:
	is_toggled = toggled_on

	if(toggled_on):
		unit_selected.emit()
	else:
		unit_unselected.emit()

### Custom Methods
func set_unit_data(unit: Unit):
	self.icon = unit.unit_res.icon


### Connected Signals
func ready_signals():
	data_node_ref = get_node("%DataNodeRefs")
	game_master = get_node("/" + data_node_ref.GAME_MASTER)

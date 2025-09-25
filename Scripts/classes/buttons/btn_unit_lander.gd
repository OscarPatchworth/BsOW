class_name BtnUnitLander # Class Name
extends Button


# signals
signal unit_selected(unit: Unit)
signal unit_unselected(unit: Unit)
# enums

# constants

# static variables
var unit_res: UnitRes
var game_master
var data_node_ref
var ui_pannel

# @export variables

# remaining regular variables
var is_toggled : bool
var unit: Unit

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
	ready_signals()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _toggled(toggled_on: bool) -> void:
	is_toggled = toggled_on

	if(toggled_on):
		unit_selected.emit(unit)
	else:
		unit_unselected.emit(unit)

### Custom Methods
func set_unit_data(unit: Unit):
	self.unit = unit
	self.icon = unit.unit_res.icon


### Connected Signals
func ready_signals():
	ui_pannel = find_parent("Panel")
	self.unit_selected.connect(ui_pannel.add_selected_unit_lander)
	self.unit_unselected.connect(ui_pannel.rmv_selected_unit_lander)	

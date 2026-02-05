#lander_control.gd
extends VBoxContainer

# signals
signal lander_control_updated
signal move_units_action_req(req: Action)

# enums

# constants

# static vars
var selector_manager: GameManager
var lander_manager: GameManager

# @export variables

# remaining regular variables
var cur_lander: Lander

# @onready variables
@onready var lander_hflow: HFlowContainer = self.find_child("Landers")
@onready var units_hflow: HFlowContainer = self.find_child("Units")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update():
	#Check for cur_lander
	cur_lander = selector_manager.get_selected_lander()
	if cur_lander == null:
		print("Lander Control in player UI has null lander selected")
		return

	update_connected_landers()
	update_unit_landers()
	lander_control_updated.emit()


func update_connected_landers():
	free_children(lander_hflow)

	var connected_landers: Array[Lander]
	connected_landers = lander_manager.get_connected_landers(cur_lander)

	for lander in connected_landers:
		var new_lnd_btn = ConnectedLanderControlButton.new()
		new_lnd_btn.bind_selector(selector_manager)
		new_lnd_btn.lander = lander
		new_lnd_btn.update_display()
		lander_hflow.add_child(new_lnd_btn)
		# Connect _pressed()
		new_lnd_btn.btn_pressed.connect(selector_manager.set_target_lander)
		new_lnd_btn.move_units_action_req.connect(fwd_move_units_req)


func update_unit_landers():
	free_children(units_hflow)

	var stationed_units = cur_lander.units # Need to make a get func()
	for unit in stationed_units:
		var new_unit_btn = UnitLanderControlButton.new()
		new_unit_btn.bind_selector(selector_manager)
		new_unit_btn.unit = unit
		new_unit_btn.update_display()
		units_hflow.add_child(new_unit_btn)
		# Setup toggle/selector 
		new_unit_btn.unit_selected.connect(selector_manager.add_unit_selected_units)
		new_unit_btn.unit_deselected.connect(selector_manager.rmv_unit_selected_units)


### Connected Signals


## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("Lander Control selector_manager bound")


func bind_lander_manager(lm: GameManager):
	lander_manager = lm
	#print("Lander Manager bound to Lander_Control")


## Get/Set (er)s

### Connected Signals
func fwd_move_units_req(req: Action):
	move_units_action_req.emit(req)

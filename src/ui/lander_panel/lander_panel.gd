# lander_panel.gd
# The root/router for the Lander (Debug) Panel

extends Panel

#region Signals
signal build_action_req(req: Action)
signal buy_unit_action_req(req: Action)
signal move_units_action_req(req: Action)
signal attack_action_req(req: Action)

#endregion

#region Scene Refs
var selector_manager: Node
var lander_manager: LanderManager

@onready var building_control: Control = self.find_child("BuildingControl")
@onready var unit_control: Control = self.find_child("UnitControl")
@onready var lander_control: Control = self.find_child("LanderControl")
@onready var biome_label: Label = find_child("BiomeLabel")
#endregion

#region Runtime Refs

#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_signals()


func update():
	var cur_lander = selector_manager.get_selected_lander()
	if(cur_lander):
		biome_label.text = str(cur_lander.biome_data.name)

		update_building_control(cur_lander)
		update_unit_control(cur_lander)	
		update_lander_control(cur_lander)


#endregion

#region Binders
func bind_selector(selector):
	selector_manager = selector
	#print("Lander Panel selector Manager bound")

	building_control.bind_selector(selector)
	unit_control.bind_selector(selector)
	lander_control.bind_selector(selector)

	connect_selector_signals()


func bind_lander_manager(lm: LanderManager):
	lander_manager = lm
	lander_control.bind_lander_manager(lm)


#endregion

#region Signal Connections
func connect_signals():
	building_control.build_action_req.connect(self.fwd_build_request)
	unit_control.buy_unit_action_req.connect(self.fwd_buy_unit_action_req)
	lander_control.move_units_action_req.connect(self.fwd_move_units_req)
	lander_control.attack_action_req.connect(self.fwd_attack_action_req)



func connect_selector_signals():
	# This signal should be done in the selector manager as that's the listener
	lander_control.lander_control_updated.connect(selector_manager.clear_selected_units)


#endregion

#region Forwarders
func fwd_build_request(req):
	build_action_req.emit(req)


func fwd_buy_unit_action_req(buy_unit_req: Action):
	buy_unit_req.target_lander = selector_manager.get_selected_lander()
	buy_unit_action_req.emit(buy_unit_req)


func fwd_move_units_req(req: Action):
	move_units_action_req.emit(req)


func fwd_attack_action_req(req: Action):
	attack_action_req.emit(req)


#endregion

#region Callbacks
func update_building_control(cur_lander: Lander):
	if cur_lander.has_building:
		building_control.set_state_building_details()
	else:
		building_control.set_state_building_shop()


func update_unit_control(cur_lander: Lander):
	if cur_lander.units.size() >= cur_lander.unit_capacity:
		unit_control.set_state_details()
	else:
		unit_control.set_state_shop()


func update_lander_control(cur_lander: Lander):
	lander_control.update()


#endregion

#region State Queries

#endregion

#region Helpers

#endregion

# End Of File
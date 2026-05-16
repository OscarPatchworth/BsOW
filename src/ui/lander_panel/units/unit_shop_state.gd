# unit_shop_state.gd
# Is logic for shop state of DebugPanel->Units

extends VBoxContainer

#region Signals
signal buy_unit_action_req(req: Action)
#endregion

#region Scene Refs
var selector: Dictionary
@onready var shop_list: ListBox = self.find_child("HListBox")
#endregion

###################################################################################################
#region Lifecycle
func update() -> void:
	var units = selector.player.species.units
	shop_list.set_objects(
		units,
		func(u): return u.name
	)
#endregion

#region Binders
func bind_selector(sel: Dictionary) -> void:
	selector = sel
	connect_signals()
#endregion

#region Signal Connections
func connect_signals() -> void:
	shop_list.list_btn_pressed.connect(on_unit_pressed)
#endregion

#region Callbacks
func on_unit_pressed(unit: UnitData) -> void:
	var action_req = Action.new()
	action_req.type = Action.RequestType.BUY_UNIT
	action_req.unit_type = unit
	action_req.target_lander = selector.selected_lander
	buy_unit_action_req.emit(action_req)
#endregion

# End Of File

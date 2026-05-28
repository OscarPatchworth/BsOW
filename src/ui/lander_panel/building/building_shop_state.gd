# building_shop_state.gd
# Is logic for Shop state of DebugPanel->Building

extends VBoxContainer

#region Signals
signal build_action_req(req: Action)
#endregion

#region Scene Refs
var selector: Dictionary
@onready var shop_list: ListBox = self.find_child("HListBox")
#endregion

###################################################################################################
#region Lifecycle
func update() -> void:
	var buildings = selector.player.species.buildings
	shop_list.set_objects(
		buildings,
		func(b): return b.name
	)
#endregion

#region Binders
func bind_selector(sel: Dictionary) -> void:
	selector = sel
	connect_signals()
#endregion

#region Signal Connections
func connect_signals() -> void:
	shop_list.list_btn_pressed.connect(on_building_pressed)
#endregion

#region Callbacks
func on_building_pressed(building: BuildingData) -> void:
	var action_req = Action.new()
	action_req.type = Action.RequestType.PLACE_BUILDING
	action_req.building_type = building
	action_req.target_lander = selector.origin_lander
	build_action_req.emit(action_req)
#endregion

# End Of File

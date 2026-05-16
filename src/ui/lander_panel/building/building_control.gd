# building_control.gd
extends VBoxContainer

#region Signals
signal build_action_req(req: Action)
#endregion

#region Enums
enum BuildingDisplay {
	HIDE_ALL,
	BUILDING_DETAILS,
	BUILDING_SHOP
}
#endregion

#region Scene Refs
var selector: Dictionary
var display_state: BuildingDisplay = BuildingDisplay.HIDE_ALL
@onready var details_node: VBoxContainer = self.find_child("DetailsState")
@onready var shop_node: VBoxContainer = self.find_child("ShopState")
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_signals()
	update_display()
#endregion

#region Binders
func bind_selector(sel: Dictionary) -> void:
	selector = sel
	details_node.bind_selector(sel)
	shop_node.bind_selector(sel)
#endregion

#region State Setters
func set_state_hide() -> void:
	display_state = BuildingDisplay.HIDE_ALL
	update_display()

func set_state_building_details() -> void:
	display_state = BuildingDisplay.BUILDING_DETAILS
	update_display()

func set_state_building_shop() -> void:
	display_state = BuildingDisplay.BUILDING_SHOP
	update_display()
#endregion

#region Display Updates
func update_display() -> void:
	match display_state:
		BuildingDisplay.HIDE_ALL:
			details_node.hide()
			shop_node.hide()
		BuildingDisplay.BUILDING_DETAILS:
			shop_node.hide()
			details_node.show()
			details_node.update()
		BuildingDisplay.BUILDING_SHOP:
			details_node.hide()
			shop_node.show()
			shop_node.update()
#endregion

#region Signal Connections
func connect_signals() -> void:
	shop_node.build_action_req.connect(fwd_build_req)
#endregion

#region Forwarders
func fwd_build_req(build_req: Action) -> void:
	build_action_req.emit(build_req)
#endregion

# End Of File

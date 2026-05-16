# unit_control.gd
extends VBoxContainer

#region Signals
signal buy_unit_action_req(req: Action)
#endregion

#region Enums
enum UnitDisplay {
	HIDE_ALL,
	DETAILS,
	SHOP
}
#endregion

#region Scene Refs
var selector: Dictionary
var display_state: UnitDisplay = UnitDisplay.HIDE_ALL
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
	display_state = UnitDisplay.HIDE_ALL
	update_display()

func set_state_details() -> void:
	display_state = UnitDisplay.DETAILS
	update_display()

func set_state_shop() -> void:
	display_state = UnitDisplay.SHOP
	update_display()
#endregion

#region Display Updates
func update_display() -> void:
	match display_state:
		UnitDisplay.HIDE_ALL:
			details_node.hide()
			shop_node.hide()
		UnitDisplay.DETAILS:
			shop_node.hide()
			details_node.show()
			details_node.update()
		UnitDisplay.SHOP:
			details_node.hide()
			shop_node.show()
			shop_node.update()
#endregion

#region Signal Connections
func connect_signals() -> void:
	shop_node.buy_unit_action_req.connect(fwd_buy_unit_action_req)
#endregion

#region Forwarders
func fwd_buy_unit_action_req(buy_unit_req: Action) -> void:
	buy_unit_action_req.emit(buy_unit_req)
#endregion

# End Of File

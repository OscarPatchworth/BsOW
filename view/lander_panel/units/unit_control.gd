#unit_control.gd
extends Control

# signals

# enums
enum UnitDisplay {
	HIDE_ALL,
	DETAILS,
	SHOP
}

# constants
#const MAX_SPEED = 200

# static variables
var selector_manager:GameManager

# @export variables

# remaining regular variables
var display_state: UnitDisplay = UnitDisplay.HIDE_ALL

# @onready variables
@onready var details_node:VBoxContainer = self.find_child("DetailsState")
@onready var shop_node:VBoxContainer = self.find_child("ShopState")


###################################################################################################
###	Methods
func _ready() -> void:
	connect_signals()
	connect_wires()

	update_display()


func get_display_state() -> UnitDisplay:
	return display_state
func set_display_state(new_state: UnitDisplay):
	display_state = new_state
	update_display()

##
func set_state_hide():
	set_display_state(UnitDisplay.HIDE_ALL)
	update_display()

func set_state_details():
	set_display_state(UnitDisplay.DETAILS)
	update_display()

func set_state_shop():
	set_display_state(UnitDisplay.SHOP)
	update_display()
##

func update_display():
	match display_state:
		UnitDisplay.HIDE_ALL:
			update_hide_all()

		UnitDisplay.DETAILS:
			update_details()

		UnitDisplay.SHOP:
			update_shop()


func update_hide_all():
	details_node.hide()
	shop_node.hide()


func update_details():
	shop_node.hide()
	details_node.show()
	details_node.update()


func update_shop():
	details_node.hide()
	shop_node.show()
	shop_node.update()

### Signals and wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	details_node.bind_selector(selector)
	shop_node.bind_selector(selector)
	#print("Building Control selector_manager bound")


func connect_signals():
	shop_node.build_action_req.connect(self.fwd_build_req)


func connect_wires():
	pass


#func fwd_build_req(build_req: Action):
#	build_action_req.emit(build_req)

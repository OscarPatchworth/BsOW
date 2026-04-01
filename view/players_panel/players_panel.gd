#players_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var turn_manager: GameManager
# @export variables

# remaining regular variables

# @onready variables
@onready var players_list: ItemList = self.find_child("ItemList")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls
func bind_turn_manager(tm: GameManager):
	# Bind self
	turn_manager = tm


func setup_turn_order_display():
	players_list.clear()
	for acotr_name in turn_manager.get_turn_order_names():
		players_list.add_item(acotr_name, null, false)

## Get/Set (er)s

### Connected Signals

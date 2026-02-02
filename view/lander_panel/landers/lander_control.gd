#lander_control.gd
extends VBoxContainer

# signals

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

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update():
	cur_lander = selector_manager.get_selected_lander()
	if cur_lander == null:
		print("Lander Control in player UI has null lander selected")
		return

	free_children(lander_hflow)	

	var connected_landers: Array[Lander]
	connected_landers = lander_manager.get_connected_landers(cur_lander)

	for lander in connected_landers:
		var new_lnd_btn = LanderControlButton.new()
		new_lnd_btn.bind_selector(selector_manager)
		new_lnd_btn.lander = lander
		new_lnd_btn.update_display()
		lander_hflow.add_child(new_lnd_btn)



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

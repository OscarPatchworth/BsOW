#players_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var turn_manager: GameManager
# @export variables

# remaining regular variables
var anchor_points := {}

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


func actor_turn_changed(active_actor: Actor):
	# Clear all first
	players_list.deselect_all()
	
	for i in range(players_list.item_count):
		var is_active = players_list.get_item_text(i) == active_actor.name
		
		if is_active:
			players_list.set_item_custom_bg_color(i, Color.PEACH_PUFF)
			players_list.set_item_custom_fg_color(i, Color.MEDIUM_BLUE)
		else:
			players_list.set_item_custom_bg_color(i, Color.TRANSPARENT)
			players_list.set_item_custom_fg_color(i, Color.GRAY)
	
	# Force redraw
	players_list.queue_redraw()
			

func game_state_changed(state):
	if state == 0: #setup
		# Save current Anchors
		anchor_points["top"] = self.anchor_top
		anchor_points["bottom"] = self.anchor_bottom
		anchor_points["left"] = self.anchor_left
		anchor_points["right"] = self.anchor_right
		
		# Adjust Setup Anchors
		anchor_top = 0.01
		# Anchor Bottom = top + margin + height
		anchor_bottom = 0.01 + (anchor_points["bottom"] - anchor_points["top"])
		# Anchor Left = Far_right - margin - width
		anchor_left = 1 - 0.005 - (anchor_points["right"] - anchor_points["left"])
		anchor_right = 1 -0.005


	elif state == 1: # Main game loop
		self.show()
	else: # Dead
		pass

## Get/Set (er)s

### Connected Signals

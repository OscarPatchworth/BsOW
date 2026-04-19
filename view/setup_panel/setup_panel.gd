#setup_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var turn_manager: GameManager
var player_self: Player
var match_settings

# @export variables

# remaining regular variables

# @onready variables
@onready var setup_landers: ListBox = self.find_child("HListBox")

###################################################################################################
###	Methods
func _ready() -> void:
	setup_landers.list_btn_pressed.connect(self.list_btn_pressed)

func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func list_btn_pressed(biome: BiomeData):
	var place_lnd = Action.new()


### Connected Signals
func bind_turn_manager(tm: GameManager):
	turn_manager = tm


func bind_player(p: Player):
	player_self = p


func bind_match_settings(ms):
	match_settings = ms

## Calls
func game_state_changed(game_state):
	if game_state == turn_manager.GameSequence.SETUP:
		self.show()
		var starting_landers = []
		for i in match_settings.starting_biomes_amount:
			if player_self.get_starting_biomes().size() > i and player_self.get_starting_biomes()[i] in match_settings.game_biomes:
				starting_landers.append(player_self.get_starting_biomes()[i])
			else:
				starting_landers.append(match_settings.game_biomes.pick_random())
		setup_landers.set_objects(starting_landers, func(p): return "", func(b): return b.poker_icon) 
	#setup_landers.set
	else: self.hide()


## Get/Set (er)s

### Connected Signals

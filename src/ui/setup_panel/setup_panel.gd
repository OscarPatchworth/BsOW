#setup_panel.gd
extends Panel

# signals
signal setup_biome_pressed(b: BiomeData)
signal all_setup_landers_placed()
# enums

# constants

# static variables
var turn_manager: TurnManager
var player_self: Player
var match_settings

# @export variables

# remaining regular variables
var starting_landers = []

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
	setup_biome_pressed.emit(biome) 


### Connected Signals
func bind_turn_manager(tm: TurnManager):
	turn_manager = tm


func bind_player(p: Player):
	player_self = p


func bind_match_settings(ms):
	match_settings = ms

## Calls
func game_state_changed(game_state):
	if match_settings == null:
		print("Setup Panel | Err | Calling null on match settings")
		return
	if game_state == turn_manager.GameSequence.SETUP:
		self.show()
		for i in match_settings.starting_biomes_amount:
			if player_self.get_starting_biomes().size() > i and player_self.get_starting_biomes()[i] in match_settings.game_biomes:
				starting_landers.append(player_self.get_starting_biomes()[i])
			else:
				starting_landers.append(match_settings.game_biomes.pick_random())
		print(player_self.get_starting_biomes())
		setup_landers.set_objects(starting_landers, func(p): return "", func(b): return b.poker_icon) 
	#setup_landers.set
	else: self.hide()


func setup_biome_placed(req: Action):
	starting_landers.erase(req.get_biome_type())
	setup_landers.set_objects(starting_landers, func(p): return "", func(b): return b.poker_icon)
	
	if starting_landers == []:
		all_setup_landers_placed.emit()

## Get/Set (er)s

### Connected Signals

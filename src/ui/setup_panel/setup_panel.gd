# setup_panel.gd
extends Panel

#region Signals
signal setup_biome_pressed(b: BiomeData)
signal all_setup_landers_placed()
#endregion

#region Scene Refs
var turn_manager: TurnManager
var player_self: Player
var match_settings
var starting_landers: Array[BiomeData] = []
@onready var setup_landers: ListBox = self.find_child("HListBox")
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_signals()
#endregion

#region Binders
func bind_turn_manager(tm: TurnManager) -> void:
	turn_manager = tm

func bind_player(p: Player) -> void:
	player_self = p

func bind_match_settings(ms) -> void:
	match_settings = ms
#endregion

#region Signal Connections
func connect_signals() -> void:
	setup_landers.list_btn_pressed.connect(biome_btn_pressed)
#endregion

#region Handlers
func biome_btn_pressed(biome: BiomeData) -> void:
	setup_biome_pressed.emit(biome)
#endregion

#region Callbacks
func game_state_changed(game_state) -> void:
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
		setup_landers.set_objects(starting_landers, func(_p): return "", func(b): return b.poker_icon)
	else:
		self.hide()

func setup_biome_placed(req: Action) -> void:
	starting_landers.erase(req.get_biome_type())
	setup_landers.set_objects(starting_landers, func(_p): return "", func(b): return b.poker_icon)
	if starting_landers == []:
		all_setup_landers_placed.emit()
#endregion

# End Of File
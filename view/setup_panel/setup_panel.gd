# setup_panel.gd
class_name SetupPanel
extends Panel

## During setup: the biomes the player still has to place. Click one, then click the world.

signal biome_selected(biome_data: BiomeData)
signal all_biomes_placed()

var _turn_manager: TurnManager
var _player: Player
var _match_settings: MatchSettings
var _remaining_biomes: Array[BiomeData] = []

@onready var _biomes_list: ListBox = find_child("HListBox")


func _ready() -> void:
	_biomes_list.item_pressed.connect(biome_selected.emit)


#region Public API
func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_player(player: Player) -> void:
	_player = player


func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings


func apply_game_state(state: TurnManager.GameState) -> void:
	if state != TurnManager.GameState.SETUP:
		hide()
		return
	show()
	_remaining_biomes = _pick_starting_biomes()
	_refresh_list()


func on_biome_placed(action: Action) -> void:
	_remaining_biomes.erase(action.get_biome_data())
	_refresh_list()
	if _remaining_biomes.is_empty():
		all_biomes_placed.emit()
#endregion


#region Private
## The species' starting biomes (if allowed in this match), topped up with random game biomes.
func _pick_starting_biomes() -> Array[BiomeData]:
	var picked: Array[BiomeData] = []
	var species_biomes := _player.get_species().get_starting_biomes()
	var game_biomes := _match_settings.get_game_biomes()
	for i in _match_settings.get_starting_biome_count():
		if i < species_biomes.size() and species_biomes[i] in game_biomes:
			picked.append(species_biomes[i])
		else:
			picked.append(game_biomes.pick_random())
	return picked


func _refresh_list() -> void:
	_biomes_list.set_items(_remaining_biomes,
		func(_biome: BiomeData) -> String: return "",
		func(biome: BiomeData) -> Texture2D: return biome.get_icon())
#endregion

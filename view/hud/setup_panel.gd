# setup_panel.gd
class_name SetupPanel
extends PanelContainer

## Bottom-centre during setup. Step 1: pick each starting biome and click open ground to place it
## (the placement preview shows where gravity pulls it). Step 2: click one of your landers to
## build your command tower.

signal biome_selected(biome_data: BiomeData)
signal all_biomes_placed()

var _player: Player
var _match_settings: MatchSettings
var _remaining_biomes: Array[BiomeData] = []
var _selected_biome: BiomeData

var _title: Label
var _buttons: HBoxContainer
var _note: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND, 10, 14))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)
	_title = HudTheme.make_label("", HudTheme.TITLE_FONT_SIZE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_buttons)
	_note = HudTheme.make_label("", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_note)
	hide()


#region Public API
func bind(player: Player, match_settings: MatchSettings) -> void:
	_player = player
	_match_settings = match_settings


func begin() -> void:
	_remaining_biomes = _pick_starting_biomes()
	show()
	_select(_remaining_biomes[0] if not _remaining_biomes.is_empty() else null)


func on_biome_placed(action: Action) -> void:
	_remaining_biomes.erase(action.get_biome_data())
	if _remaining_biomes.is_empty():
		_selected_biome = null
		_refresh()
		all_biomes_placed.emit()
	else:
		_select(_remaining_biomes[0] if action.get_biome_data() == _selected_biome else _selected_biome)


func get_remaining_biomes() -> Array[BiomeData]:
	return _remaining_biomes
#endregion


#region Private
func _select(biome_data: BiomeData) -> void:
	_selected_biome = biome_data
	_refresh()
	biome_selected.emit(biome_data)


func _refresh() -> void:
	for child in _buttons.get_children():
		child.free()
	if _remaining_biomes.is_empty():
		_title.text = "Click one of your landers to build your %s" % _player.get_species().get_command_tower().get_display_name()
		_note.text = "It becomes your home base. Then the game begins."
		return
	_title.text = "Place your starting landers (%d left)" % _remaining_biomes.size()
	_note.text = "Pick a biome, then click open ground. Landers close together pull into each other."
	for biome_data in _remaining_biomes:
		var upkeep := HudTheme.format_cost(biome_data.get_upkeep())
		var button := HudTheme.make_button("%s\n%s" % [biome_data.get_display_name(), "no upkeep" if upkeep == "free" else "+" + upkeep])
		button.toggle_mode = true
		button.button_pressed = biome_data == _selected_biome
		button.custom_minimum_size = Vector2(130, 56)
		if biome_data.get_icon() != null:
			button.icon = biome_data.get_icon()
			button.expand_icon = true
		button.pressed.connect(_select.bind(biome_data))
		_buttons.add_child(button)


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
#endregion

# match_setup_screen.gd
class_name MatchSetupScreen
extends Control

## Before a match: pick your race (or Random) and how many AI opponents, then Start.
## The choices go to MatchRequest, which GameRoot reads when the game scene starts.

const START_SCENE := "res://scenes/menus/start_screen.tscn"
const GAME_SCENE := "res://main.tscn"
const CARD_SIZE := Vector2(360, 430)

## The races to choose from (set in match_setup_screen.tscn).
@export var species_options: Array[SpeciesData] = []

## null = Random.
var _chosen_species: SpeciesData
var _opponents: int = 2
var _race_group := ButtonGroup.new()
var _opponent_group := ButtonGroup.new()
var _summary: Label


func _ready() -> void:
	theme = HudTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackdrop.new())
	# Start from the last match's choices, so Back -> Play keeps them.
	_chosen_species = MatchRequest.player_species
	if MatchRequest.opponent_count > 0:
		_opponents = MatchRequest.opponent_count

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND_SOLID, 14, 26))
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	column.add_child(HudTheme.make_label("New match", 36))
	column.add_child(HudTheme.make_label("Your race", HudTheme.TITLE_FONT_SIZE, HudTheme.MUTED))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	column.add_child(cards)
	for species in species_options:
		cards.add_child(_race_card(species))
	cards.add_child(_race_card(null))

	column.add_child(HSeparator.new())
	var opponents_row := HBoxContainer.new()
	opponents_row.add_theme_constant_override("separation", 10)
	opponents_row.add_child(HudTheme.make_label("Opponents", HudTheme.TITLE_FONT_SIZE, HudTheme.MUTED))
	for count in range(MatchRequest.MIN_OPPONENTS, MatchRequest.MAX_OPPONENTS + 1):
		var button := HudTheme.make_button("%d AI%s" % [count, "" if count == 1 else "s"])
		button.name = "Opponents%d" % count
		button.toggle_mode = true
		button.button_group = _opponent_group
		button.custom_minimum_size = Vector2(96, 44)
		button.button_pressed = count == _opponents
		button.pressed.connect(_on_opponents_chosen.bind(count))
		opponents_row.add_child(button)
	opponents_row.add_child(HudTheme.make_label("   Free-for-all: every AI plays for itself.", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))
	column.add_child(opponents_row)

	column.add_child(HSeparator.new())
	var bottom := HBoxContainer.new()
	var back := HudTheme.make_button("‹  Back")
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(140, 50)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(START_SCENE))
	bottom.add_child(back)
	_summary = HudTheme.make_label("", HudTheme.FONT_SIZE, HudTheme.MUTED)
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_summary)
	var start := HudTheme.make_button("Start match  ▸", true)
	start.name = "StartButton"
	start.custom_minimum_size = Vector2(220, 50)
	start.add_theme_font_size_override("font_size", 20)
	start.pressed.connect(start_match)
	bottom.add_child(start)
	column.add_child(bottom)
	_refresh_summary()


#region Public API
## Saves the choices and loads the game.
func start_match() -> void:
	MatchRequest.set_choices(_chosen_species, _opponents)
	get_tree().change_scene_to_file(GAME_SCENE)


func get_chosen_species() -> SpeciesData:
	return _chosen_species


func get_opponent_count() -> int:
	return _opponents
#endregion


#region Private
## A big toggle button describing `species` (null = Random).
func _race_card(species: SpeciesData) -> Button:
	var card := Button.new()
	card.name = "Race_" + (species.get_display_name() if species != null else "Random")
	card.toggle_mode = true
	card.button_group = _race_group
	card.custom_minimum_size = CARD_SIZE if species != null else Vector2(200, CARD_SIZE.y)
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", HudTheme.panel_style(HudTheme.RAISED, 12, 16))
	card.add_theme_stylebox_override("hover", HudTheme.panel_style(HudTheme.RAISED.lightened(0.08), 12, 16))
	var chosen_style := HudTheme.panel_style(HudTheme.ACCENT.darkened(0.55), 12, 16)
	chosen_style.border_color = HudTheme.ACCENT
	chosen_style.set_border_width_all(3)
	card.add_theme_stylebox_override("pressed", chosen_style)
	card.add_theme_stylebox_override("hover_pressed", chosen_style)
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	card.button_pressed = species == _chosen_species
	card.pressed.connect(_on_species_chosen.bind(species))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	if species == null:
		box.add_child(_card_label("Random", 28))
		box.add_child(_card_label("Let the dust cloud decide.", HudTheme.FONT_SIZE, HudTheme.MUTED))
		return card

	box.add_child(_card_label(species.get_display_name(), 28))
	box.add_child(_card_label(species.get_description(), HudTheme.SMALL_FONT_SIZE + 1, HudTheme.MUTED))
	box.add_child(_card_label("Traits", HudTheme.SMALL_FONT_SIZE, HudTheme.ACCENT))
	for ability in species.get_abilities():
		box.add_child(_card_label("• %s: %s" % [ability.get_display_name(), ability.get_description()], HudTheme.SMALL_FONT_SIZE))
	box.add_child(_card_label("Units", HudTheme.SMALL_FONT_SIZE, HudTheme.ACCENT))
	for unit_data in species.get_units():
		var damage := unit_data.get_damage()
		var line := "• %s  %dd%d" % [unit_data.get_display_name(), damage.get_dice_count(), damage.get_dice_sides()]
		for ability in unit_data.get_abilities():
			line += "  (%s)" % ability.get_display_name()
		box.add_child(_card_label(line, HudTheme.SMALL_FONT_SIZE))
	return card


func _card_label(text: String, font_size: int, color: Color = HudTheme.TEXT) -> Label:
	var label := HudTheme.make_label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.x = 160
	return label


func _on_species_chosen(species: SpeciesData) -> void:
	_chosen_species = species
	_refresh_summary()


func _on_opponents_chosen(count: int) -> void:
	_opponents = count
	_refresh_summary()


func _refresh_summary() -> void:
	_summary.text = "%s vs %d AI%s" % [_chosen_species.get_display_name() if _chosen_species != null else "Random race",
		_opponents, "" if _opponents == 1 else "s"]
#endregion

#seasons_panel.gd
extends Panel
# signals

# enums

# constants

# static variables
var turn_manager: GameManager
# @export variables

# remaining regular variables
var game_seasons: Array

# @onready variables
@onready var hbox: HBoxContainer = self.find_child("HBoxContainer")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func to_sentence_case(txt: String) -> String:
	var words = txt.split("_")
	for i in range(words.size()):
		words[i] = words[i].to_lower().capitalize()
	return " ".join(words)


### Connected Signals
func bind_turn_manager(tm: GameManager):
	# Bind self
	turn_manager = tm


## Calls
func seasons_generated():
	free_children(hbox)
	game_seasons = turn_manager.get_season_order_names()
	for season in game_seasons:
		var new_label = Label.new()
		new_label.text = to_sentence_case(season)
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(new_label)
		new_label.size_flags_vertical = Control.SIZE_FILL
		new_label.size_flags_horizontal = Control.SIZE_FILL
		new_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# DEFER: Wait one frame for layout	
	await get_tree().process_frame
	season_changed(0)


func season_changed(sea_indx: int):
	print("Season panel | Season changed | Current season: " + str(game_seasons[sea_indx]))
	for i in range(hbox.get_child_count()):
		var label = hbox.get_child(i) as Label
		var new_sb = StyleBoxFlat.new()

		if i == sea_indx:
			new_sb.bg_color = turn_manager.get_season_color(turn_manager.get_season(game_seasons[sea_indx]))
		else:
			new_sb.bg_color = Color.DIM_GRAY
		label.add_theme_stylebox_override("normal", new_sb)


## Get/Set (er)s

### Connected Signals

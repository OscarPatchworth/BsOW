#turn_panel.gd
extends Node

# signals

# enums

# constants

# static @onready variables
var turn_manager = GameManager

# @export var variables
@export var defualt_label_stylebox: StyleBox
@export var defualt_label_font: Font

@export var active_label_stylebox: StyleBox
@export var active_label_font: Font

# remaining regular @onready variables

# @onready @onready variables
@onready var upkeep_label: Label = self.find_child("Upkeep")
@onready var dust_label: Label = self.find_child("DustcloudCollapse")
@onready var comabt_label: Label = self.find_child("Combat")
@onready var reinforcement_label: Label = self.find_child("Reinforcement")
@onready var cleanup_label: Label = self.find_child("Cleanup")

@onready var phase_labels: Array[Label] = [
	upkeep_label,
	dust_label,
	comabt_label,
	reinforcement_label,
	cleanup_label,
]


###################################################################################################
###	Methods
func update_turn_display(turn_phase: int):
	defualt_phase_labels()
	if turn_phase == turn_manager.GameLoop.UPKEEP:
		upkeep_label.add_theme_stylebox_override("normal", active_label_stylebox)
		upkeep_label.add_theme_font_override("font", active_label_font)


func defualt_phase_labels():
	for label in phase_labels:
		label.add_theme_stylebox_override("normal", defualt_label_stylebox)
		label.add_theme_font_override("font", defualt_label_font)

### Connected Signals
func bind_turn_manager(tm: GameManager):
	self.turn_manager = tm
	update_turn_display(turn_manager.get_game_phase())
	


## Calls

## Get/Set (er)s

### Connected Signals

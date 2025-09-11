
extends Control

# signals

# enums

# constants

# static variables
var panel: Panel
var vbox: VBoxContainer
var title_box: Label
var title_event: Label
var label_break: Label

var label_step1: Label
var label_step2: Label
var label_step3: Label
var label_step4: Label
var label_step5: Label
var label_event1: Label
var label_event2: Label
var label_event3: Label

var game_master

# @export variables

# remaining regular variables

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.    
func _ready() -> void:
	ready_children()
	ready_refs()
	ready_signals()
	panel.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func ready_children() -> void:
	panel = get_child(0)
	vbox = panel.get_child(0)
	title_box = vbox.find_child("Title")
	title_event = vbox.find_child("EventTitle")
	label_break = vbox.find_child("Break")

	label_event1 = vbox.find_child("Step1")
	label_event2 = vbox.find_child("Step2")
	label_event3 = vbox.find_child("Step3")
	label_step1 = vbox.find_child("Step1")
	label_step2 = vbox.find_child("Step2")
	label_step3 = vbox.find_child("Step3")
	label_step4 = vbox.find_child("Step4")
	label_step5 = vbox.find_child("Step5")
	label_break = vbox.find_child("Break")


func update_display(player_state: int) -> void:
	match  player_state:
		0:
			panel.hide()
		_:
			panel.show()
	print(player_state)


### Connected Signals
func ready_refs() -> void:
	game_master = get_node("/" + data_node_ref.GAME_MASTER)

func ready_signals() -> void:
	game_master.player_change_state.connect(self.update_display)

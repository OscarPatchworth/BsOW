#turn_panel.gd
extends Panel

# signals
signal next_phase_req(req: Action)


# enums

# constants
var turn_manager: TurnManager
# static @onready variables

# @export var variables
@export var defualt_label_stylebox: StyleBox
@export var active_label_stylebox: StyleBox

# remaining regular @onready variables
var turn_phases: Array

# @onready @onready variables
@onready var hbox: HBoxContainer = self.find_child("HBoxContainer")
@onready var next_btn: Button = self.find_child("NextButton")

###################################################################################################
###	Methods
func _ready() -> void:
	ready_signals()



func generate_phase_labels():
	generate_turn_phases()

	for phase in turn_phases:
		var new_label = Label.new()
		new_label.text = phase
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(new_label)
		new_label.size_flags_vertical = Control.SIZE_FILL
		new_label.size_flags_horizontal = Control.SIZE_FILL
		new_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	update_turn_panel()


func generate_turn_phases():
	turn_phases = []
	for phase in turn_manager.GameLoop:
		turn_phases.append(to_sentence_case(phase))
	print(turn_phases)
	

func to_sentence_case(txt: String) -> String:
	var words = txt.split("_")
	for i in range(words.size()):
		words[i] = words[i].to_lower().capitalize()
	return " ".join(words)


func update_turn_panel():
	if turn_manager == null:
		print("Turn Panel | Err | calling null turn_mangaer")
		return
	# to_sentnce_case wrapper to compare states equally in for-loop below
	var current_phase = to_sentence_case(
		turn_manager.int_to_game_phase(
		turn_manager.get_game_phase())
	)

	for i in range(turn_phases.size()):
		if turn_phases[i] == current_phase:
			hbox.get_child(i).add_theme_stylebox_override("normal", active_label_stylebox)
		else:
			hbox.get_child(i).add_theme_stylebox_override("normal", defualt_label_stylebox)


func next_phase_btn_pressed():
	var new_action = Action.new()
	new_action.set_type(Action.RequestType.PROGRESS_TURN)
	next_phase_req.emit(new_action)

### Connected Signals
func bind_turn_manager(tm: TurnManager):
	self.turn_manager = tm
	generate_phase_labels()
	

func ready_signals():
	next_btn.pressed.connect(self.next_phase_btn_pressed)


## Calls
func game_phase_changed(game_phase):
	update_turn_panel()


func game_state_changed(state):
	if state == 0: #setup
		self.hide()
	elif state == 1: # Main game loop
		self.show()
	else: # Dead
		pass

## Get/Set (er)s

### Connected Signals

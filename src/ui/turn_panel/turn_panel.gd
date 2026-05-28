# turn_panel.gd
extends Panel

#region Signals
signal next_phase_req(req: Action)
#endregion

#region Scene Refs
var turn_manager: TurnManager
var turn_phases: Array
@export var default_label_stylebox: StyleBox
@export var active_label_stylebox: StyleBox
@onready var hbox: HBoxContainer = self.find_child("HBoxContainer")
@onready var next_btn: Button = self.find_child("NextButton")
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_signals()

func game_state_changed(state: int) -> void:
	match state:
		0: self.hide()  # Setup
		1: self.show()  # Game Loop
#endregion

#region Binders
func bind_turn_manager(tm: TurnManager) -> void:
	turn_manager = tm
	generate_phase_labels()
#endregion

#region Signal Connections
func connect_signals() -> void:
	next_btn.pressed.connect(next_phase_btn_pressed)
#endregion

#region Handlers
func next_phase_btn_pressed() -> void:
	var new_action = Action.new()
	new_action.set_type(Action.RequestType.PROGRESS_TURN)
	next_phase_req.emit(new_action)
#endregion

#region Callbacks
func game_phase_changed(_game_phase) -> void:
	update_turn_panel()
#endregion

#region Display Updates
func generate_phase_labels() -> void:
	generate_turn_phases()
	for phase in turn_phases:
		var new_label = Label.new()
		new_label.text = phase
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		new_label.size_flags_vertical = Control.SIZE_FILL
		new_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(new_label)
	update_turn_panel()

func generate_turn_phases() -> void:
	turn_phases = []
	for phase in turn_manager.GameLoop:
		turn_phases.append(to_sentence_case(phase))

func update_turn_panel() -> void:
	if turn_manager == null:
		print("Turn Panel | Err | calling null turn_manager")
		return
	var current_phase = to_sentence_case(
		turn_manager.int_to_game_phase(turn_manager.get_game_phase())
	)
	for i in range(turn_phases.size()):
		var stylebox = active_label_stylebox if turn_phases[i] == current_phase else default_label_stylebox
		hbox.get_child(i).add_theme_stylebox_override("normal", stylebox)
#endregion

#region Helpers
func to_sentence_case(txt: String) -> String:
	var words = txt.split("_")
	for i in range(words.size()):
		words[i] = words[i].to_lower().capitalize()
	return " ".join(words)
#endregion

# End Of File

# turn_panel.gd
class_name TurnPanel
extends Panel

## The phases of a turn with the current phase highlighted, plus a "next phase" button.

signal action_requested(action: Action)

@export var default_label_stylebox: StyleBox
@export var active_label_stylebox: StyleBox

var _turn_manager: TurnManager

@onready var _labels_box: HBoxContainer = find_child("HBoxContainer")
@onready var _next_button: GameButton = find_child("NextButton")


func _ready() -> void:
	_next_button.pressed.connect(_on_next_button_pressed)


#region Public API
func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager
	_build_phase_labels()


func refresh() -> void:
	var current_index := _turn_manager.get_game_phase() as int
	for i in _labels_box.get_child_count():
		var stylebox := active_label_stylebox if i == current_index else default_label_stylebox
		_labels_box.get_child(i).add_theme_stylebox_override("normal", stylebox)


func apply_game_state(state: TurnManager.GameState) -> void:
	match state:
		TurnManager.GameState.SETUP:
			hide()
		TurnManager.GameState.MAIN_LOOP:
			show()
#endregion


#region Signal handlers
func _on_next_button_pressed() -> void:
	action_requested.emit(Action.create(Action.Type.PROGRESS_TURN))
#endregion


#region Private
## One label per TurnManager.Phase, in enum order (so label index == phase value).
func _build_phase_labels() -> void:
	for phase_name in TurnManager.get_phase_names():
		var label := Label.new()
		label.text = TextUtils.to_title_case(phase_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_FILL
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_labels_box.add_child(label)
	refresh()
#endregion

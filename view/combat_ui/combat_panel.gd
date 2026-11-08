# combat_panel.gd
class_name CombatPanel
extends Panel

## The combat screen: both sides' chosen units, unit/ability pickers, and the fight button.

signal unit_selected(unit: UnitInstance)
signal unit_deselected(unit: UnitInstance)
signal ready_pressed()
signal not_ready_pressed()
signal display_toggled(is_hidden: bool)
signal action_requested(action: Action)
signal closed()

var _player: Player
var _contest: Contest
var _is_combat_finished: bool = false

@onready var _own_units_panel: CombatUnitsPanel = find_child("SelfUnitsPanel")
@onready var _opponent_units_panel: CombatUnitsPanel = find_child("OppUnitsPanel")
@onready var _attack_ability_panel: AttackAbilityPanel = find_child("AttackAbilitiesPanel")
@onready var _defend_ability_panel: DefendAbilityPanel = find_child("DefendAbilitiesPanel")
@onready var _select_units_panel: SelectUnitsPanel = find_child("SelectUnitsPanel")
@onready var _select_ability_panel: SelectAbilityPanel = find_child("SelectAbilitiesPanel")
@onready var _fight_button: FightButton = find_child("FightButton")
@onready var _toggle_display_button: GameButton = find_child("ToggleDisplayButton")
@onready var _exit_button: GameButton = find_child("ExitCombatButton")
@onready var _repeat_button: GameButton = find_child("RepeatCombatButton")


func _ready() -> void:
	_select_units_panel.unit_selected.connect(unit_selected.emit)
	_own_units_panel.unit_deselected.connect(unit_deselected.emit)
	_opponent_units_panel.unit_deselected.connect(unit_deselected.emit)
	_fight_button.ready_pressed.connect(ready_pressed.emit)
	_fight_button.not_ready_pressed.connect(not_ready_pressed.emit)
	_toggle_display_button.toggled.connect(_on_toggle_display_button_toggled)
	_exit_button.pressed.connect(_on_exit_button_pressed)
	_repeat_button.pressed.connect(_on_repeat_button_pressed)


#region Public API
func bind_combat_manager(combat_manager: CombatManager) -> void:
	_own_units_panel.bind_combat_manager(combat_manager)
	_opponent_units_panel.bind_combat_manager(combat_manager)


func bind_player(player: Player) -> void:
	_player = player
	_select_units_panel.bind_player(player)
	_select_ability_panel.bind_player(player)
	_fight_button.bind_player(player)


## Starts showing a new contest.
func open(contest: Contest) -> void:
	_is_combat_finished = false
	_exit_button.hide()
	_repeat_button.hide()
	refresh(contest)


func refresh(contest: Contest) -> void:
	_contest = contest
	var own_side: int = contest.get_side_of(_player)
	_own_units_panel.set_side(own_side)
	_opponent_units_panel.set_side(Contest.get_opposite_side(own_side))

	_own_units_panel.refresh(contest)
	_opponent_units_panel.refresh(contest)
	_attack_ability_panel.refresh(contest)
	_defend_ability_panel.refresh(contest)
	_select_units_panel.refresh(contest)
	_select_ability_panel.refresh(contest)
	_fight_button.refresh(contest)


func show_outcome(outcomes: Array[CombatOutcome]) -> void:
	_is_combat_finished = true
	_exit_button.show()
	if _contest.get_actor(Contest.Side.ATTACKER) == _player:
		_repeat_button.show()
	_own_units_panel.show_outcome(outcomes)
	_opponent_units_panel.show_outcome(outcomes)
#endregion


#region Signal handlers
func _on_toggle_display_button_toggled(is_hidden: bool) -> void:
	for child in get_children():
		if child != _toggle_display_button:
			child.visible = not is_hidden
	_toggle_display_button.text = "Show Combat Display" if is_hidden else "Hide Combat Display"
	display_toggled.emit(is_hidden)


func _on_exit_button_pressed() -> void:
	if not _is_combat_finished:
		push_warning("CombatPanel | Exit pressed while combat is still running")
		return
	# Deferred so other end-of-combat handlers can still read the contest this frame.
	set_deferred("_contest", null)
	hide()
	closed.emit()


func _on_repeat_button_pressed() -> void:
	if not _is_combat_finished or _contest.get_actor(Contest.Side.ATTACKER) != _player:
		return
	var attack := Action.create(Action.Type.ATTACK)
	attack.set_source_lander(_contest.get_lander(Contest.Side.ATTACKER))
	attack.set_target_lander(_contest.get_lander(Contest.Side.DEFENDER))
	_on_exit_button_pressed()
	action_requested.emit(attack)
#endregion

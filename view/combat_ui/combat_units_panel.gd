# combat_units_panel.gd
class_name CombatUnitsPanel
extends Panel

## One column of unit slots for one side of a contest (up to that side's max units).

signal unit_deselected(unit: UnitInstance)

enum Alignment {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	CENTER,
}

## Slot height : gap height ratio, and the outer margin (fraction of the panel).
const SLOT_RATIO: int = 2
const GAP_RATIO: int = 1
const VERTICAL_MARGIN: float = 0.02
## Horizontal extents of a slot (fractions of the panel width).
const SLOT_LENGTH: float = 1.168
const SLOT_MARGIN: float = 0.02

@export var unit_display_scene: PackedScene
@export var fill_alignment: Alignment
@export var bar_color: Color

var _combat_manager: CombatManager
var _side: int = Contest.Side.ATTACKER
var _contest: Contest


#region Public API
func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager


func refresh(contest: Contest) -> void:
	_contest = contest
	for child in get_children():
		child.queue_free()
	_build_slots(contest)


## Shows each slot's roll and slides the slots into ranked order.
func show_outcome(outcomes: Array[CombatOutcome]) -> void:
	var side_units := _contest.get_units(_side)
	var side_outcomes := outcomes.filter(func(o: CombatOutcome) -> bool: return o.get_unit() in side_units)

	for display: SelectedCombatUnitsDisplay in get_children():
		var unit := display.get_unit()
		if unit == null:
			continue
		for rank in side_outcomes.size():
			if side_outcomes[rank].get_unit() == unit:
				display.show_outcome(side_outcomes[rank])
				_tween_slot_to(display, rank)
				break
#endregion


#region Accessors
func get_side() -> int:
	return _side


func set_side(value: int) -> void:
	_side = value
#endregion


#region Private
func _build_slots(contest: Contest) -> void:
	var chosen_units := contest.get_units(_side)
	var display_state := SelectedCombatUnitsDisplay.DisplayState.READY if contest.is_ready(_side) \
		else SelectedCombatUnitsDisplay.DisplayState.SELECTING

	for i in _combat_manager.get_max_units(_side):
		var display: SelectedCombatUnitsDisplay = unit_display_scene.instantiate()
		if fill_alignment == Alignment.RIGHT_TO_LEFT:
			display.set_fill_direction(SelectedCombatUnitsDisplay.FillDirection.RIGHT_TO_LEFT)
		display.unit_deselected.connect(unit_deselected.emit)
		add_child(display)

		# Slots are laid out by hand (and tweened), so pin the anchors; stretch anchors would
		# override the size.
		display.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var rect := _slot_rect(i)
		display.position = rect.position
		display.size = rect.size
		display.set_color(bar_color)
		display.set_display_state(display_state)
		display.set_unit(chosen_units[i] if i < chosen_units.size() else null)


## Pixel rect of slot `index` within this panel.
func _slot_rect(index: int) -> Rect2:
	var slot_count := _combat_manager.get_max_units(_side)
	var segment := (1.0 - 2.0 * VERTICAL_MARGIN) / (slot_count * SLOT_RATIO + (slot_count - 1) * GAP_RATIO)
	var top := index * (SLOT_RATIO + GAP_RATIO) * segment + VERTICAL_MARGIN
	var bottom := top + SLOT_RATIO * segment

	var left := SLOT_MARGIN
	var right := SLOT_LENGTH
	if fill_alignment != Alignment.LEFT_TO_RIGHT:
		left = 1.0 - SLOT_LENGTH
		right = 1.0 - SLOT_MARGIN

	return Rect2(left * size.x, top * size.y, (right - left) * size.x, (bottom - top) * size.y)


func _tween_slot_to(display: Control, index: int, duration: float = 1.0) -> void:
	var rect := _slot_rect(index)
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(display, "position", rect.position, duration)
	tween.tween_property(display, "size", rect.size, duration)
#endregion

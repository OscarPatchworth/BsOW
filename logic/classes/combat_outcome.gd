# combat_outcome.gd
class_name CombatOutcome
extends RefCounted

## The result of one unit's damage roll in a contest.

enum Outcome {
	DEAD,
	ALIVE,
}

enum Reason {
	COMBAT_LOST,
	COMBAT_WON,
	ABILITY_SAVED,
	ABILITY_LOST,
	ABILITY_WON,
	NO_COMBAT,
}

const REASON_TEXT := {
	Reason.COMBAT_LOST: "Unit fell in combat",
	Reason.COMBAT_WON: "Unit survived combat",
	Reason.ABILITY_SAVED: "Unit was doomed but saved by an ability",
	Reason.ABILITY_LOST: "Unit had the high ground but was thwarted by an ability",
	Reason.ABILITY_WON: "Unit clutched victory with help from an ability",
	Reason.NO_COMBAT: "Unit slept in and missed the fight",
}

var _unit: UnitInstance
var _rolls: Array[int] = []
var _modifiers: Array[int] = []
var _total: int = 0
var _outcome: Outcome = Outcome.ALIVE
var _reason: Reason = Reason.NO_COMBAT


func _init(unit: UnitInstance = null) -> void:
	_unit = unit


#region Public API
static func get_reason_text(reason: Reason) -> String:
	return REASON_TEXT.get(reason, "")


## Rolls the unit's damage dice, applies the modifier, and stores the total.
func roll_damage() -> void:
	var damage := get_unit().get_damage()
	for i in damage.get_dice_count():
		add_roll(randi_range(1, damage.get_dice_sides()))
	add_modifier(damage.get_modifier())
	set_total(calculate_total())


func calculate_total() -> int:
	return _sum(get_rolls()) + _sum(get_modifiers())


func add_roll(roll: int) -> void:
	var rolls := get_rolls().duplicate()
	rolls.append(roll)
	set_rolls(rolls)


func clear_rolls() -> void:
	set_rolls([] as Array[int])


func add_modifier(modifier: int) -> void:
	var modifiers := get_modifiers().duplicate()
	modifiers.append(modifier)
	set_modifiers(modifiers)


func clear_modifiers() -> void:
	set_modifiers([] as Array[int])


func to_debug_dictionary() -> Dictionary:
	return {
		"unit": get_unit().get_display_name() if get_unit() else "",
		"rolls": get_rolls(),
		"modifiers": get_modifiers(),
		"total": get_total(),
		"outcome": Outcome.find_key(get_outcome()),
		"reason": get_reason_text(get_reason()),
	}
#endregion


#region Accessors
func get_unit() -> UnitInstance:
	return AbilitySystem.resolve_get(self, &"unit", _unit)


func set_unit(value: UnitInstance) -> void:
	_unit = AbilitySystem.resolve_set(self, &"unit", _unit, value)


func get_rolls() -> Array[int]:
	return AbilitySystem.resolve_get(self, &"rolls", _rolls)


func set_rolls(value: Array[int]) -> void:
	_rolls = AbilitySystem.resolve_set(self, &"rolls", _rolls, value)


func get_modifiers() -> Array[int]:
	return AbilitySystem.resolve_get(self, &"modifiers", _modifiers)


func set_modifiers(value: Array[int]) -> void:
	_modifiers = AbilitySystem.resolve_set(self, &"modifiers", _modifiers, value)


func get_total() -> int:
	return AbilitySystem.resolve_get(self, &"total", _total)


func set_total(value: int) -> void:
	_total = AbilitySystem.resolve_set(self, &"total", _total, value)


func get_outcome() -> Outcome:
	return AbilitySystem.resolve_get(self, &"outcome", _outcome)


func set_outcome(value: Outcome) -> void:
	_outcome = AbilitySystem.resolve_set(self, &"outcome", _outcome, value)


func get_reason() -> Reason:
	return AbilitySystem.resolve_get(self, &"reason", _reason)


## Setting the reason also sets the matching outcome (DEAD/ALIVE).
func set_reason(value: Reason) -> void:
	match value:
		Reason.COMBAT_LOST, Reason.ABILITY_LOST:
			set_outcome(Outcome.DEAD)
		Reason.COMBAT_WON, Reason.ABILITY_SAVED, Reason.ABILITY_WON:
			set_outcome(Outcome.ALIVE)
		_:
			push_warning("CombatOutcome | set_reason() called with a reason that has no outcome")
			return
	_reason = AbilitySystem.resolve_set(self, &"reason", _reason, value)
#endregion


#region Private
func _sum(numbers: Array[int]) -> int:
	var total := 0
	for n in numbers:
		total += n
	return total
#endregion

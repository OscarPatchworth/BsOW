# econ_data.gd
class_name EconData
extends Resource

## A bundle of game resources. Used for costs, upkeep, and actor wallets.

signal amounts_changed()

const RESOURCE_KEYS: Array[StringName] = [&"gold", &"food", &"mineral", &"wood", &"stone"]

@export var gold: int = 0
@export var food: int = 0
@export var mineral: int = 0
@export var wood: int = 0
@export var stone: int = 0


#region Public API
## True if every amount in `cost` is covered by this bundle.
func can_afford(cost: EconData) -> bool:
	for key in RESOURCE_KEYS:
		if cost.get_amount(key) > get_amount(key):
			return false
	return true


func add(other: EconData) -> void:
	for key in RESOURCE_KEYS:
		_write_amount(key, get_amount(key) + other.get_amount(key))
	amounts_changed.emit()


func subtract(other: EconData) -> void:
	for key in RESOURCE_KEYS:
		_write_amount(key, get_amount(key) - other.get_amount(key))
	amounts_changed.emit()


## Returns { "gold": 3, "food": 0, ... } using the (ability-resolved) amounts.
func to_dictionary() -> Dictionary:
	var amounts := {}
	for key in RESOURCE_KEYS:
		amounts[String(key)] = get_amount(key)
	return amounts
#endregion


#region Accessors
func get_amount(key: StringName) -> int:
	if key not in RESOURCE_KEYS:
		push_error("EconData | Unknown resource key: %s" % key)
		return 0
	return AbilitySystem.resolve_get(self, key, get(key))


func set_amount(key: StringName, value: int) -> void:
	if key not in RESOURCE_KEYS:
		push_error("EconData | Unknown resource key: %s" % key)
		return
	_write_amount(key, value)
	amounts_changed.emit()
#endregion


#region Private
func _write_amount(key: StringName, value: int) -> void:
	set(key, AbilitySystem.resolve_set(self, key, get(key), value))
#endregion

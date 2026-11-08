# selector_manager.gd
class_name SelectorManager
extends Node

## What the local player currently has selected in the UI. View state only (not hooked).

signal selected_units_changed()

var _player: Player
var _selected_lander: Lander
var _target_lander: Lander
var _selected_units: Array[UnitInstance] = []


#region Public API
func bind_player(player: Player) -> void:
	_player = player


func select_lander(lander: Lander) -> void:
	set_selected_lander(lander)


func add_selected_unit(unit: UnitInstance) -> void:
	if unit in _selected_units:
		push_warning("SelectorManager | Unit is already selected")
		return
	_selected_units.append(unit)
	selected_units_changed.emit()


func remove_selected_unit(unit: UnitInstance) -> void:
	if unit not in _selected_units:
		push_warning("SelectorManager | Unit is not selected")
		return
	_selected_units.erase(unit)
	selected_units_changed.emit()


func clear_selected_units() -> void:
	_selected_units = []
#endregion


#region Accessors
func get_player() -> Player:
	return _player


func get_selected_lander() -> Lander:
	return _selected_lander


func set_selected_lander(value: Lander) -> void:
	_selected_lander = value


func get_target_lander() -> Lander:
	return _target_lander


func set_target_lander(value: Lander) -> void:
	_target_lander = value


func get_selected_units() -> Array[UnitInstance]:
	return _selected_units
#endregion

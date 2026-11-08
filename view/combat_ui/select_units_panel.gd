# select_units_panel.gd
class_name SelectUnitsPanel
extends Panel

## Lists the player's units on their side's lander that aren't chosen yet. Click to choose one.

signal unit_selected(unit: UnitInstance)

var _player: Player

@onready var _button_container: Container = find_child("VBoxContainer")
@onready var _lockout_panel: Panel = find_child("LockOutPanel")


#region Public API
func bind_player(player: Player) -> void:
	_player = player


func refresh(contest: Contest) -> void:
	var side: int = contest.get_side_of(_player)
	# Lock the picker once the player has declared ready.
	_lockout_panel.visible = contest.is_ready(side)

	for child in _button_container.get_children():
		child.queue_free()

	var chosen_units := contest.get_units(side)
	for unit in contest.get_lander(side).get_units():
		if unit in chosen_units:
			continue
		var button := SelectUnitButton.new()
		button.set_unit(unit)
		button.unit_selected.connect(unit_selected.emit)
		_button_container.add_child(button)
#endregion

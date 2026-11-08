# select_ability_panel.gd
class_name SelectAbilityPanel
extends Panel

## Lists the abilities the player could commit to this contest. (Abilities aren't implemented yet,
## so this currently always shows "No Abilities Available".)

const EMPTY_MESSAGE_NAME := "EmptyMessage"

var _player: Player

@onready var _button_container: Container = find_child("VBoxContainer")
@onready var _lockout_panel: Panel = find_child("LockOutPanel")


#region Public API
func bind_player(player: Player) -> void:
	_player = player


func refresh(contest: Contest) -> void:
	var side: int = contest.get_side_of(_player)
	_lockout_panel.visible = contest.is_ready(side)

	for child in _button_container.get_children():
		child.queue_free()
	var old_message := find_child(EMPTY_MESSAGE_NAME, false, false)
	if old_message != null:
		old_message.queue_free()

	# TODO(AbilitySystem): gather abilities from the player and from contest.get_units(side).
	var abilities: Array = []

	if abilities.is_empty():
		var message := Label.new()
		message.name = EMPTY_MESSAGE_NAME
		message.text = "No Abilities Available"
		add_child(message)
#endregion

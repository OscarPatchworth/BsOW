# fight_button.gd
class_name FightButton
extends GameButton

## Toggles the player's ready state in combat. Shows "FIGHT" until pressed, then "READY".

signal ready_pressed()
signal not_ready_pressed()

const TILT_DEGREES: float = 12.0

var _player: Player
var _is_player_ready: bool = false


func _pressed() -> void:
	if _is_player_ready:
		not_ready_pressed.emit()
	else:
		ready_pressed.emit()


#region Public API
func bind_player(player: Player) -> void:
	_player = player


func refresh(contest: Contest) -> void:
	var side := contest.get_side_of(_player)
	_is_player_ready = side != -1 and contest.is_ready(side)
	text = "READY" if _is_player_ready else "FIGHT"
	rotation_degrees = -TILT_DEGREES if _is_player_ready else TILT_DEGREES
#endregion

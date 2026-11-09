# web_instance.gd
class_name WebInstance
extends RefCounted

## A web spun on a lander (EnwebAbility). It lasts `turns_left` more of its owner's upkeeps.

var _owner_actor: Actor
var _ability: EnwebAbility
var _turns_left: int = 0


func _init(owner_actor: Actor = null, ability: EnwebAbility = null) -> void:
	_owner_actor = owner_actor
	_ability = ability
	if ability != null:
		_turns_left = ability.get_duration_turns()


#region Accessors
func get_owner_actor() -> Actor:
	return AbilitySystem.resolve_get(self, &"owner_actor", _owner_actor)


func get_ability() -> EnwebAbility:
	return AbilitySystem.resolve_get(self, &"ability", _ability)


func get_turns_left() -> int:
	return AbilitySystem.resolve_get(self, &"turns_left", _turns_left)


func set_turns_left(value: int) -> void:
	_turns_left = AbilitySystem.resolve_set(self, &"turns_left", _turns_left, value)
#endregion

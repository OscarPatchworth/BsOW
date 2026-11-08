# damage_data.gd
class_name DamageData
extends Resource

## A damage roll: `dice_count` d `dice_sides` + `modifier`  (e.g. 2d6+1).

@export var dice_count: int = 1
@export var dice_sides: int = 6
@export var modifier: int = 0


#region Accessors
func get_dice_count() -> int:
	return AbilitySystem.resolve_get(self, &"dice_count", dice_count)


func set_dice_count(value: int) -> void:
	dice_count = AbilitySystem.resolve_set(self, &"dice_count", dice_count, value)


func get_dice_sides() -> int:
	return AbilitySystem.resolve_get(self, &"dice_sides", dice_sides)


func set_dice_sides(value: int) -> void:
	dice_sides = AbilitySystem.resolve_set(self, &"dice_sides", dice_sides, value)


func get_modifier() -> int:
	return AbilitySystem.resolve_get(self, &"modifier", modifier)


func set_modifier(value: int) -> void:
	modifier = AbilitySystem.resolve_set(self, &"modifier", modifier, value)
#endregion

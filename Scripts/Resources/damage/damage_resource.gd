extends Resource
class_name DamageRes  # Optional, but helpful

@export var name: String

@export var damage_dice_amount: int
@export var damage_dice_type: int
@export var damage_dice_modifier: int

func get_damage_dict() -> Dictionary:
	return {
		"amount" : damage_dice_amount,
		"dice" : damage_dice_type,
		"mod" : damage_dice_modifier,
	}

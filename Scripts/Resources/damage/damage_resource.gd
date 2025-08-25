extends Resource
class_name DamageRes  # Optional, but helpful

@export var name: String

@export var damage_dice_amount: int = 0
@export var damage_dice_type: int = 0
@export var damage_dice_modifier: int = 0

func get_damage_dict() -> Dictionary:
	return {
		"amount" : damage_dice_amount,
		"dice" : damage_dice_type,
		"mod" : damage_dice_modifier,
	}

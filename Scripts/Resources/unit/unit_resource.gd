extends Resource
class_name UnitRes  # Optional, but helpful

@export var name: String
@export var description: String
@export var mesh: PackedScene
@export var cost: CostRes

@export var damage_dice_amount = 1
@export var damage_dice_type = 6
@export var damage_dice_modifier = 0

#@export var abilities: Array[Ability]


func get_damage_dict() -> Dictionary:
    return {
        "amount" : damage_dice_amount,
        "dice" : damage_dice_type,
        "mod" : damage_dice_modifier,
    }

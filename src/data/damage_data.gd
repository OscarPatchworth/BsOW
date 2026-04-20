#damage_data.gd
class_name DamageData
extends Resource

@export var damage_dice_amount: int
@export var damage_dice: int 

@export var damage_mod: int


###################################################################################################
func get_dice_amount() -> int:
	return damage_dice_amount
func set_dice_amount(amount: int):
	damage_dice_amount = amount


func get_damage_dice() -> int:
	return damage_dice
func set_damage_dice(die: int):
	damage_dice = die


func get_damage_mod() -> int:
	return damage_mod
func set_damage_mod(mod: int):
	damage_mod = mod
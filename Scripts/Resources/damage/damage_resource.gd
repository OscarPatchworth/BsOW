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

### Coded by Gemini ... I didn't know godot had obj.get() & obj.set() funcs ... thats rlly cool
func add_damage(dmg: DamageRes) -> void:
	# Get the dictionary from the passed-in resource
	var other_resources = dmg.get_damage_dict()

	# Iterate over the keys of the current resource
	for res_key in get_damage_dict().keys():
		# Add the value from the other resource to the current one
		if other_resources.has(res_key):
			# `set()` and `get()` are useful for dynamic property access
			var current_value = self.get(res_key)
			var other_value = other_resources[res_key]
			self.set(res_key, current_value + other_value)
extends Resource
class_name CostRes

@export var gold: int = 0
@export var food: int = 0
@export var mineral: int = 0
@export var wood: int = 0
@export var stone: int = 0

func get_resource_dict() -> Dictionary:
	return {
		"gold": gold,
		"food": food,
		"mineral": mineral,
		"wood": wood,
		"stone": stone,
	}

# Func coded by chatGPT
func set_resource_value(key: String, value: int) -> void:
	if key in ["gold", "food", "mineral", "wood", "stone"]:
		self.set(key, value)  # modifies the exported property directly

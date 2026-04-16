#econ_data.gd
class_name EconData
extends Resource


@export var gold: int = 0
@export var food: int = 0
@export var mineral: int = 0
@export var wood: int = 0
@export var stone: int = 0

var keys = ["gold","food","mineral","wood","stone"]

###################################################################################################
###	Methods
func get_resource_dict() -> Dictionary:
	return {
		"gold": gold,
		"food": food,
		"mineral": mineral,
		"wood": wood,
		"stone": stone,
	}


func cost_less_than(ec: EconData) -> bool:
	for key in keys:
		if self.get(key) > ec.get(key):
			return false
	return true


func rmv_resource(cost: EconData):
	for key in keys:
		self.set(key, self.get(key) - cost.get(key))
	print(get_resource_dict())

# Func coded by chatGPT
func set_resource_value(key: String, value: int) -> void:
	if key in ["gold", "food", "mineral", "wood", "stone"]:
		self.set(key, value)  # modifies the exported property directly
func get_resource_value(key: String) -> int:
	if key in ["gold", "food", "mineral", "wood", "stone"]:
		return self.get(key)
	else: return -1



### Coded by Gemini ... I didn't know godot had obj.get() & obj.set() funcs ... thats rlly cool
func add_cost(cost: CostRes) -> void:
	# Get the dictionary from the passed-in resource
	var other_resources = cost.get_resource_dict()

	# Iterate over the keys of the current resource
	for res_key in get_resource_dict().keys():
		# Add the value from the other resource to the current one
		if other_resources.has(res_key):
			# `set()` and `get()` are useful for dynamic property access
			var current_value = self.get(res_key)
			var other_value = other_resources[res_key]
			self.set(res_key, current_value + other_value)

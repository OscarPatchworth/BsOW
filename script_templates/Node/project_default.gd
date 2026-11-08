# meta-description: BsOW layout: hooked accessors, typed binds, ordered sections
# meta-default: true
# _CLASS_SNAKE_CASE_.gd
class_name _CLASS_
extends _BASE_

## One-line description of what this script is responsible for.

# --- Signals (events: past tense, requests: *_requested) ---

# --- Enums ---

# --- Constants ---

# --- @export (authored values) ---

# --- Injected dependencies (set via bind_*) ---

# --- Private state (_snake_case, read/write through accessors) ---
var _example_value: int = 0

# --- @onready node references ---


#region Public API
#endregion


#region Accessors
func get_example_value() -> int:
	return AbilitySystem.resolve_get(self, &"example_value", _example_value)


func set_example_value(value: int) -> void:
	_example_value = AbilitySystem.resolve_set(self, &"example_value", _example_value, value)
#endregion


#region Signal handlers (_on_<source>_<signal>)
#endregion


#region Private
#endregion

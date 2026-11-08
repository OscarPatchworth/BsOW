# ability_system.gd
# Autoload singleton, registered in project.godot as "AbilitySystem".
extends Node

## The single interception point for gameplay state.
##
## Every hooked getter in the game ends with:
##     return AbilitySystem.resolve_get(self, &"property", _property)
## Every hooked setter writes through:
##     _property = AbilitySystem.resolve_set(self, &"property", _property, value)
##
## Right now both functions are pass-throughs: they hand back the original value.
## When abilities are added, this is where they get to inspect, override or veto a value.
##
##   target   - the object that owns the value (a UnitInstance, Lander, EconData, ...)
##   property - the property name, matching the getter/setter name without get_/set_
##   value    - the stored (base) value
##
## Search the codebase for "resolve_get(" / "resolve_set(" to list every hook point.


func resolve_get(_target: Object, _property: StringName, base_value: Variant) -> Variant:
	return base_value


func resolve_set(_target: Object, _property: StringName, _current_value: Variant, new_value: Variant) -> Variant:
	return new_value

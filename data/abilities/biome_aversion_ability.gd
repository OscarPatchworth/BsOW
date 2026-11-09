# biome_aversion_ability.gd
class_name BiomeAversionAbility
extends Ability

## A race trait: its units won't move onto a `biome` lander. (They can still attack one and
## defend one they already stand on.) They will go in to take or raze an enemy building there,
## or a command tower on that biome could never be razed and the game couldn't be won.

@export var biome: BiomeData


func check_move(unit: UnitInstance, _from: Lander, to: Lander) -> String:
	var takes_enemy_building := to.has_building() and to.get_building().get_owner_actor() != unit.get_owner_actor()
	if is_trait_of(unit) and to.get_biome_data() == biome and not takes_enemy_building:
		return "%s won't set foot on %s (%s)" % [unit.get_display_name(), biome.get_display_name(), get_display_name()]
	return ""

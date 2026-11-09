# biome_stride_ability.gd
class_name BiomeStrideAbility
extends Ability

## A race trait: moving from one `biome` lander to another doesn't use up the unit's move,
## so its units can run along a chain of them in one turn.

@export var biome: BiomeData


func move_spends_movement(unit: UnitInstance, from: Lander, to: Lander) -> bool:
	return not (is_trait_of(unit) and from.get_biome_data() == biome and to.get_biome_data() == biome)

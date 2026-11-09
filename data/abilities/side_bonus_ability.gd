# side_bonus_ability.gd
class_name SideBonusAbility
extends Ability

## A race trait: its units get `bonus` on their combat roll when fighting on `side`, on a
## `biome` lander if one is set (e.g. Ettercap Lurkers: +1 defending a Mountain).

@export var bonus: int = 1
## Contest.Side (an int: see CONVENTIONS.md on enums across classes).
@export_enum("Attacker", "Defender") var side: int = Contest.Side.DEFENDER
## Only on landers of this biome (anywhere if empty).
@export var biome: BiomeData


func modify_roll(outcome: CombatOutcome, unit: UnitInstance, lander: Lander, _contest: Contest, fighting_side: int) -> void:
	if fighting_side == side and is_trait_of(unit) and (biome == null or lander.get_biome_data() == biome):
		outcome.add_modifier(bonus, get_display_name())

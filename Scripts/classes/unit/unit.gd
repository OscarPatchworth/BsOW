class_name unit
extends RefCounted

# signals

# enums

# constants

# static variables
var unit_res: UnitRes

# @export variables

# remaining regular variables
var cost_mod: CostRes
var dmg_mod: DamageRes

var cost_total:CostRes
var damage_total:DamageRes
#var temp_abilities: Array[Ability]

###################################################################################################
###	Methods
### Custom Methods
func setup(unit: UnitRes) -> void:
    cost_mod = CostRes.new()
    dmg_mod = DamageRes.new()
    cost_total = CostRes.new()
    damage_total = DamageRes.new()

    unit_res = unit
    pass

func get_dmg_total() -> DamageRes:
    damage_total = unit_res.damage.duplicate()
    damage_total.add_damage(dmg_mod)

    return damage_total


func get_cost_total() -> CostRes:
    cost_total = unit_res.cost.duplicate()
    cost_total.add_cost(cost_mod)

    return cost_total
### Connected Signals
class_name unit
extends RefCounted

# signals

# enums

# constants

# static variables

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
    pass


### Connected Signals
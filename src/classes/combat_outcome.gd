#combat_outcome.gd
class_name CombatOutcome
#extends Node

# signals

# enums
enum Outcome {
	DEAD,
	ALIVE
}

enum Reasons {
	COMBAT_LOST,
	COMBAT_WON,
	ABILITY_SAVED,
	ABILITY_LOST,
	ABILITY_WON,
	NO_COMBAT
}

const REASON_TXT:= {
	Reasons.COMBAT_LOST : "Unit fell in combat",
	Reasons.COMBAT_WON : "Unit survived combat",
	Reasons.ABILITY_SAVED : "Unit was doomed by saved by ability",
	Reasons.ABILITY_LOST : "Unit had the high ground but was thawted by ability",
	Reasons.ABILITY_WON : "Unit Clutched victory with help from ability",
	Reasons.NO_COMBAT : "Unit slept in and missed the fight"	
}


# constants

# static variables

# @export variables

# remaining regular variables
var unit: UnitObject
var rolls: Array[int]
var mods: Array[int]
var total: int
var outcome: Outcome = Outcome.ALIVE
var reason: Reasons = Reasons.NO_COMBAT

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func sum(numbs: Array[int]) -> int:
	if numbs.size() == 1:
		return numbs[0]
	elif numbs == []:
		return 0.0
	else:
		numbs[0] = numbs[0] + numbs[-1]
		numbs.pop_back()
		return sum(numbs)


func get_reason_text(r: Reasons) -> String:
	if r != null: return REASON_TXT[r]
	else: return ""


### Connected Signals


## Calls

## Get/Set (er)s
func get_unit() -> UnitObject:
	return unit
func set_unit(unitobj: UnitObject):
	unit = unitobj


func get_rolls() -> Array[int]:
	return rolls
func add_roll(roll: int):
	rolls.append(roll)
func clear_rolls():
	rolls = []


func get_mods() -> Array[int]:
	return mods
func add_mod(mod: int):
	mods.append(mod)
func clear_mods():
	mods = []


func get_total() -> int:
	return total
func set_total(dmg_total: int):
	total = dmg_total
func calc_total() -> int:
	return sum(rolls) + sum(mods)
func clear_total():
	total = -1 # null


func get_outcome() -> Outcome:
	return outcome
func get_reason() -> Reasons:
	return reason
func set_reason(r: Reasons):
	reason = r
	match r:
		Reasons.COMBAT_LOST, Reasons.ABILITY_LOST:
			outcome = Outcome.DEAD
		Reasons.COMBAT_WON, Reasons.ABILITY_SAVED, Reasons.ABILITY_WON:
			outcome = Outcome.ALIVE
		_:
			print("Combat Outcome | ERR | Non valid reason set")
			return
	

func get_debug() -> Dictionary:
	return {
		"unit" : unit.get_unit_data().get_unit_name(),
		"rolls" : rolls,
		"mods" : mods,
		"total" : total,
		"outcome" : outcome,
		"reason" : get_reason_text(reason)
	}

### Connected Signals

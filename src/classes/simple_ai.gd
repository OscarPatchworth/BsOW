#simple_ai.gd
class_name SimpleAI
extends Actor

# signals
signal combat_unit_selected(unit: UnitObject)
signal combat_ready(actor: Actor)
signal unit_deslected(unit: UnitObject)
signal combat_not_ready(actor: Actor)

# enums

# constants

# static variables

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func enter_combat(contest: Contest):
	print("Sai |  Entering Combat")
	var max_units = combat_manager.get_max_defend_units() if combat_pos == CombatSide.ATTAKING else combat_manager.get_max_attack_units()
	
	var units: Array[UnitObject]
	if combat_pos == CombatSide.ATTAKING: units = contest.get_invading_lander().get_units().duplicate()
	else: units = contest.get_contested_lander().get_units().duplicate()

	for i in max_units:
		if units.size() > 0:
			var chosen_unit: UnitObject = units.pick_random()
			combat_unit_selected.emit(chosen_unit)
			units.erase(chosen_unit)
	combat_ready.emit(self)


func combat_update(contest: Contest):
	pass

### Connected Signals


## Calls

## Get/Set (er)s

### Connected Signals

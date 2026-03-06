#combat_manager.gd
extends GameManager

# signals
signal combat_started(contest: Contest)
signal combat_updated(contest: Contest)

# enums
enum CombatLoop {
	START,
	SELECT,
	DAMAGE,
	CLEANUP
}


# constants

# static variables
var match_settings: Node 

var max_attack_units: int
var max_defend_units: int

var max_attack_ablt: int
var max_defend_ablt: int

# @export variables

# remaining regular variables
var combat_phase: CombatLoop = CombatLoop.START

var current_combat: Contest

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func action_to_contest(req: Action) -> Contest:
	var contest = Contest.new()
	contest.set_contested_lander(req.target_lander)
	contest.set_invading_lander(req.selected_lander)
	return contest

## Calls
func bind_match_settings(ms: Node):
	match_settings = ms

	max_attack_units = match_settings.max_attack_units
	max_defend_units = match_settings.max_defend_units
	max_attack_ablt = match_settings.max_attack_ablt
	max_defend_ablt = match_settings.max_defend_ablt



func attack_action(req: Action):
	#print("Combat Manager | Combat Req recieved")
	var combat_state = action_to_contest(req)
	# other stuffs/edits
	current_combat = combat_state

	combat_started.emit(current_combat)


func actor_selected_unit(unit:UnitObject):
	if current_combat.get_invading_actor() == unit.get_owned_by():
		if current_combat.get_invading_units().size() >= max_attack_units:
			print("Combat Manager | Attacker selecting too many units to attack w/")
		else:
			current_combat.add_invading_unit(unit)
			combat_updated.emit(current_combat)
			#print("Combat Manager | actor_selected_unit| combat_updated emiited")
			

func actor_deselected_unit(unit: UnitObject):
	if current_combat.get_invading_actor() == unit.get_owned_by():
		current_combat.rmv_invading_unit(unit)
		combat_updated.emit(current_combat)
		#print("Combat Manager | actor_selected_unit| combat_updated emiited")


func player_ready(ready_player: Actor):
	if current_combat.get_invading_actor() == ready_player:
		current_combat.set_invading_ready(true)
	elif current_combat.get_defending_actor() == ready_player:
		current_combat.set_defending_ready(true)
	else: 
		print("Combat Manager | ERROR | Actor outside of combat declared Ready")
		return
	#print("Combat Manager | Player Ready recieved")
	combat_updated.emit(current_combat)


func player_unready(unready_player: Actor):
	if current_combat.get_invading_actor() == unready_player:
		current_combat.set_invading_ready(false)
	elif current_combat.get_defending_actor() == unready_player:
		current_combat.set_defending_ready(false)
	else: 
		print("Combat Manager | ERROR | Actor outside of combat declared not Ready")
		return
	#print("Combat Manager | Player not Ready recieved")
	combat_updated.emit(current_combat)

## Get/Set (er)s
func get_max_attack_units() -> int:
	return max_attack_units
func set_max_attack_units(max_u: int):
	max_attack_units = max_u


func get_max_defend_units() -> int:
	return max_defend_units
func set_max_defend_units(max_u: int):
	max_defend_units = max_u


func get_max_attack_ablt() -> int:
	return max_attack_ablt
func set_max_attack_ablt(max_a: int):
	max_attack_ablt = max_a


func get_max_defend_ablt() -> int:
	return max_defend_ablt
func set_max_defend_ablt(max_a: int):
	max_defend_ablt = max_a



### Connected Signals

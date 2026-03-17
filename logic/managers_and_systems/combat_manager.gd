#combat_manager.gd
extends GameManager

# signals
signal combat_started(contest: Contest)
signal combat_updated(contest: Contest)
signal combat_outcome(c_out: Array[CombatOutcome])

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


func sum(numbs: Array[int]) -> int:
	if numbs.size() == 1:
		return numbs[0]
	elif numbs == []:
		return 0.0
	else:
		numbs[0] = numbs[0] + numbs[-1]
		numbs.pop_back()
		return sum(numbs)


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
	elif current_combat.get_defending_actor() == unit.get_owned_by():
		if current_combat.get_defending_units().size() >= max_defend_units:
			print("Combat Manager | Defender selecting too many units to attack w/")

		else:
			current_combat.add_defending_unit(unit)
			combat_updated.emit(current_combat)
			#print("Combat Manager | actor_selected_unit| combat_updated emiited")
	else:
		return # ERROR


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
	

	if current_combat.get_invading_ready() and current_combat.get_defending_ready():
		run_damage_phase()
	else: combat_updated.emit(current_combat)


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


func run_damage_phase():
	print("Combat Manager | @ run damage phase")
	# Calc Damage

	# Calc Invading
	var invading_dmg: Array[CombatOutcome] = []
	for unit in current_combat.invading_units:
		var unit_dmg = CombatOutcome.new()
		unit_dmg.set_unit(unit)

		var unit_dmg_data = unit.get_unit_data().get_dmg()
		for die in unit_dmg_data.get_dice_amount():
			var roll = (randi() % unit_dmg_data.get_damage_dice()) + 1
			unit_dmg.add_roll(roll)
		
		unit_dmg.add_mod(unit_dmg_data.get_damage_mod())
		unit_dmg.set_total(unit_dmg.calc_total())

		invading_dmg.append(unit_dmg)
	#print(invading_dmg)

	# Calc Defending
	var defending_dmg: Array[CombatOutcome] = []
	for unit in current_combat.defending_units:
		var unit_dmg = CombatOutcome.new()
		unit_dmg.set_unit(unit)

		var unit_dmg_data = unit.get_unit_data().get_dmg()
		for die in unit_dmg_data.get_dice_amount():
			var roll = (randi() % unit_dmg_data.get_damage_dice()) + 1
			unit_dmg.add_roll(roll)
		
		unit_dmg.add_mod(unit_dmg_data.get_damage_mod())
		unit_dmg.set_total(unit_dmg.calc_total())

		defending_dmg.append(unit_dmg)
	#print(invading_dmg)

	# Calc Outcome
	invading_dmg.sort_custom(func(a, b): return a.get_total() > b.get_total())
	defending_dmg.sort_custom(func(a, b): return a.get_total() > b.get_total())

	for i in range(min(invading_dmg.size(), defending_dmg.size())):
		#if i >= defending_dmg.size():
		# Use > bcs if tie give win to Defending
		if invading_dmg[i].get_total() > defending_dmg[i].get_total():
			invading_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_WON)
			defending_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_LOST)
		else:
			invading_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_LOST)
			defending_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_WON)

	for unit in invading_dmg:
		print(unit.get_debug())
	print("#####")
	for unit in defending_dmg:
		print(unit.get_debug())

	combat_outcome.emit(invading_dmg + defending_dmg)

	# Apply Outcome
	#for attacker in invading_dmg:
	#	if attacker.get_outcome() == CombatOutcome.Outcome.DEAD:
	#		current_combat.get_invading_lander().rmv_units([attacker.get_unit()])
	#for defender in defending_dmg:
	#	if defender.get_outcome() == CombatOutcome.Outcome.DEAD:
	#		current_combat.get_contested_lander().rmv_units([defender.get_unit()])


	#print("Combat Manager | Combat outcome emitted")
	#combat_started.emit(current_combat)


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

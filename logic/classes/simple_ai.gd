# simple_ai.gd
class_name SimpleAI
extends Actor

## A placeholder opponent. On its turn it buys units where it can and moves on;
## in combat it picks random units and declares ready. It doesn't place landers,
## move or attack yet.


#region Virtual overrides
func _take_phase(phase: TurnManager.Phase) -> void:
	if phase == TurnManager.Phase.BUYING:
		_buy_units()
	request_action(Action.create(Action.Type.PROGRESS_TURN))


func _enter_combat(contest: Contest) -> void:
	print("SimpleAI | Entering combat")
	var side: int = get_combat_side()
	var max_units := _combat_manager.get_max_units(side)
	var available_units := contest.get_lander(side).get_units().duplicate()

	for i in max_units:
		if available_units.is_empty():
			break
		var chosen_unit: UnitInstance = available_units.pick_random()
		available_units.erase(chosen_unit)
		var select := Action.create(Action.Type.SELECT_COMBAT_UNIT)
		select.set_units([chosen_unit] as Array[UnitInstance])
		request_action(select)

	request_action(Action.create(Action.Type.DECLARE_COMBAT_READY))
#endregion


#region Private
## Buys one affordable unit on each owned lander that can spawn one.
func _buy_units() -> void:
	# The purchases resolve after this step, so track what's left to spend here.
	var budget := EconData.new()
	budget.add(get_wallet())
	for lander in _lander_manager.get_landers_owned_by(self):
		if lander.is_full():
			continue
		for purchasable in lander.get_purchasables(self):
			var unit_data := purchasable as UnitData
			if unit_data == null or not budget.can_afford(unit_data.get_cost()):
				continue
			budget.subtract(unit_data.get_cost())
			var purchase := Action.create(Action.Type.PURCHASE)
			purchase.set_target_lander(lander)
			purchase.set_purchasable(unit_data)
			request_action(purchase)
			break
#endregion

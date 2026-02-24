#combat_manager.gd
extends GameManager

# signals
signal combat_started(contest: Contest)

# enums
enum CombatLoop {
	START,
	SELECT,
	DAMAGE,
	CLEANUP
}


# constants

# static variables

# @export variables

# remaining regular variables
var combat_phase: CombatLoop = CombatLoop.START

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()

func generate_contest_data(req: Action) -> Contest:
	var contest = Contest.new()
	contest.set_contested_lander(req.target_lander)
	contest.set_invading_lander(req.selected_lander)
	return contest

### Connected Signals


## Calls
func attack_action(req: Action):
	#print("Combat Manager | Combat Req recieved")
	combat_started.emit(generate_contest_data(req))


## Get/Set (er)s

### Connected Signals

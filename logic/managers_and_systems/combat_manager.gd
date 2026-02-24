#combat_manager.gd
extends GameManager

# signals

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


### Connected Signals


## Calls
func attack_action(req: Action):
	#print("Combat Manager | Combat Req recieved")
	pass


## Get/Set (er)s

### Connected Signals

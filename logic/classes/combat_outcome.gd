#combat_outcome.gd
class_name CombatOutcome
#extends Node

# signals

# enums
enum Outcome {
	LOST,
	WON
}

enum Reasons {
	COMBAT_LOST,
	COMBAT_WON,
	ABILITY_SAVED,
	ABILITY_LOST,
	ABILITY_WON
}

const REASON_TXT:= {
	Reasons.COMBAT_LOST : "Unit fell in combat",
	Reasons.COMBAT_WON : "Unit survived combat",
	Reasons.ABILITY_SAVED : "Unit was doomed by saved by ability",
	Reasons.ABILITY_LOST : "Unit had the high ground but was thawted by ability",
	Reasons.ABILITY_WON : "Unit Clutched victory with help from ability"	
}


# constants

# static variables

# @export variables

# remaining regular variables
var invading_outcome: Dictionary = {}
var defending_outcone: Dictionary = {}


# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls

## Get/Set (er)s

### Connected Signals

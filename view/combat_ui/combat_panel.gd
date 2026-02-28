#combat_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var combat_manager: GameManager


# @export variables

# remaining regular variables

# @onready variables
@onready var attack_units_pannel: Panel = self.find_child("AttackUnitsPanel")
@onready var defend_units_panel: Panel = self.find_child("DefendUnitsPanel")
@onready var attack_ablt_panel: Panel = self.find_child("AttackAbilitiesPanel")
@onready var defend_ablt_panel: Panel = self.find_child("DefendAbilitiesPanel")
@onready var select_units_panel: Panel = self.find_child("SelectUnitsPanel")
@onready var select_ablt_panel: Panel = self.find_child("SelectAbilitiesPanel")
@onready var fight_btn: GameButton = self.find_child("FightBtn")



###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()

func update(combat_state: Contest):
	### Code taken from chatGPT
	for child in get_children():
		if child.has_method("update"):
			child.update(combat_state)
	###


### Connected Signals


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Combat UI | Combat Manager Bound")

	### Code taken from chatGPT
	for child in get_children():
		if child.has_method("bind_combat_manager"):
			child.bind_combat_manager(cm)
	###


func setup_combat_display(contest: Contest):
	print("Combat UI | @ setup()")
	update(contest)


## Get/Set (er)s

### Connected Signals

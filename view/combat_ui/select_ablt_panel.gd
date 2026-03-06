#select_ablt_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var combat_manager: GameManager
var player_self: Player
# @export variables

# remaining regular variables

# @onready variables
@onready var ablt_btn_container: Container = self.find_child("VBoxContainer")
@onready var lockout_panel: Panel = self.find_child("LockOutPanel")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Select units Panel | comabt UI | Combat Manager Bound")


func bind_player(p: Player):
	player_self = p
	for child in get_children():
		if child.has_method("bind_player"):
			child.bind_player(p)


func update(combat_state: Contest):
	if (!combat_state.get_invading_ready() and !combat_state.get_defending_ready()) :
		lockout_panel.hide()
	elif(
		combat_state.get_invading_actor() == player_self and combat_state.get_invading_ready()
		or  combat_state.get_defending_actor() == player_self and combat_state.get_defending_ready()):
			lockout_panel.show()
	else: lockout_panel.hide()	
	
	
	free_children(ablt_btn_container)
	var msg_box = find_child("msg")
	if msg_box != null:
		msg_box.queue_free()


	var ablts: Array = []
	var units: Array[UnitObject]

	if combat_state.get_invading_actor() == player_self:
		units = combat_state.get_invading_units()
	else:
		units = combat_state.get_defending_units()

	#ablt.append(player_self.get_ablts())

	for unit in units:
		#ablts.append(unit.get_ablts())
		pass

	#for ablt in ablts:
		#var new_btn = GameButton.new()
		#new_btn.icon = ablt.icon
		#new_btn.add_hover_text(ablt.get_detials())

	if ablts == []:
		var msg = Label.new()
		msg.text = "No Abilities Available"
		add_child(msg)


## Get/Set (er)s

### Connected Signals

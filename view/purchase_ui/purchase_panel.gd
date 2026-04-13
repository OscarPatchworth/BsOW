#purchase_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var lander_manager: GameManager
var player_self: Player


# @export variables

# remaining regular variables

# @onready variables
@onready var lander_listbox: ListBox = self.find_child("LandersListBox")
@onready var market_listbox: ListBox = self.find_child("MarketListBox")
@onready var finish_btn: GameButton = self.find_child("FinishBtn")


###################################################################################################
###	Methods
func _ready() -> void:
	self.hide()


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls
func bind_lander_manager(lm: GameManager):
	lander_manager = lm


func bind_player(p: Player):
	player_self = p


func run_market():
	self.show()
	var landers = lander_manager.get_landers_actor_has(player_self)
	lander_listbox.set_objects(landers, func(lnd): return lnd.get_biome().name)
	#lander_listbox.set_objects(landers.map(func(lnd): return {"object": lnd, "text" : lnd.get_biome().name}))

## Get/Set (er)s

### Connected Signals

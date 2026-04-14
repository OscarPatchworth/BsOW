#purchase_panel.gd
extends Panel

# signals

signal purchase_action_req(req: Action)
# enums

# constants

# static variables
var lander_manager: GameManager
var player_self: Player


# @export variables

# remaining regular variables
var active_lander: Lander

# @onready variables
@onready var lander_listbox: ListBox = self.find_child("LandersListBox")
@onready var market_listbox: ListBox = self.find_child("MarketListBox")
@onready var finish_btn: GameButton = self.find_child("FinishBtn")


###################################################################################################
###	Methods
func _ready() -> void:
	self.hide()
	lander_listbox.list_btn_pressed.connect(self.lander_btn_pressed)
	market_listbox.list_btn_pressed.connect(self.market_btn_pressed)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func lander_btn_pressed(lnd: Lander):
	active_lander = lnd
	# Get purchases from lander
	var lander_purchases = []
	# Add any building Upgrades
	lander_purchases + lnd.get_purchases()["Building upgrades"]
	for unit in player_self.get_species().units:
		if unit.get_type() in lnd.get_purchases()["Unit Types"]:
			lander_purchases.append(unit)


	market_listbox.set_objects(lander_purchases, func(purchasable): return purchasable.name)
	

func market_btn_pressed(item):
	var buy_req = Action.new()
	buy_req.set_type(Action.RequestType.BUY)
	buy_req.set_actor(player_self)
	buy_req.set_selected_lander(active_lander)
	buy_req.set_purchasable(item)
	purchase_action_req.emit(buy_req)


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
	
	# Adjust btns
	var lander_btns = lander_listbox.get_btns()
	for i in range(lander_btns.size()):
		# If lander doesn't have purchases disable it's btn
		if !landers[i].has_purchases():
			lander_btns[i].disabled = true

			
## Get/Set (er)s

### Connected Signals

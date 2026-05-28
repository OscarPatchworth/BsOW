# building_details_state.gd
# Is logic for defualt state of DebugPanel->Building

extends VBoxContainer

#region Scene Refs
var selector: Dictionary
@onready var building_label: Label = self.find_child("BuildingNameLabel")
#endregion

###################################################################################################
#region Lifecycle
func update() -> void:
	building_label.text = selector.origin_lander.get_building_data().get_building_name()
#endregion

#region Binders
func bind_selector(sel: Dictionary) -> void:
	selector = sel
#endregion

# End Of File

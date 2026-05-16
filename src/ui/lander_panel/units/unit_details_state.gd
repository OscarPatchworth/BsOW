# unit_details_state.gd
# Is logic for shop defualt of DebugPanel->Units

extends VBoxContainer

#region Scene Refs
var selector: Dictionary
#endregion

###################################################################################################
#region Lifecycle
func update() -> void:
	pass
#endregion

#region Binders
func bind_selector(sel: Dictionary) -> void:
	selector = sel
#endregion

# End Of File

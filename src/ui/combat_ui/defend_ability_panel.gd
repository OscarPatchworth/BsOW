# defend_ablt_panel.gd
extends Panel

#region Scene Refs
var combat_manager: CombatManager
#endregion

###################################################################################################
#region Lifecycle
func update(_contest: Contest) -> void:
	pass # Placeholder — ability system not yet implemented
#endregion

#region Binders
func bind_combat_manager(cm: CombatManager) -> void:
	combat_manager = cm
#endregion

# End Of File

extends CanvasLayer
@export var pause_panel:Panel
@onready var current_scene:Level = $"../GameLayer/Main2D"

func pause():
	get_tree().paused = true
	pause_panel.visible = true
	
	
func unpause():
	get_tree().paused = false
	pause_panel.visible = false
	
func quit_game():
	get_tree().quit()

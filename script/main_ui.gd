extends CanvasLayer

signal start_game

var count:Label
var score:Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	count = $UI/HBoxContainer/VBoxContainer/Count
	score = $UI/HBoxContainer/VBoxContainer/Score

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_data(count_value, score_value):
	count.text = "%d" % count_value
	score.text = "%d" % score_value

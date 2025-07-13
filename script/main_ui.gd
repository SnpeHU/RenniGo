extends CanvasLayer

signal start_game

@onready var count:Label = $UI/VBoxContainer/HBoxContainer2/Count
@onready var score:Label = $UI/VBoxContainer/HBoxContainer/Score
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_data(count_value, score_value):
	set_count(count_value)
	set_score(score_value)

func set_count(count_value):
	count.text = "%d" % count_value

func set_score(score_value):
	score.text = "%d" % score_value
	
	

extends Node


func save()->void:
	var config = ConfigFile.new()
	config.set_value("Score_Data","high_score",Data.high)
	config.save("user://player_data.cfg")
	
	print("saved!")

func load()->void:
	var config = ConfigFile.new()
	var result =  config.load("user://player_data.cfg")
	if result == OK:
		Data.high = config.get_value("Score_Data","high_score")

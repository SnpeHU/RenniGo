extends Node

var key = "Sample"

func save()->void:
	var config = ConfigFile.new()
	config.set_value("Score_Data","high_score",Data.high)
	config.save_encrypted_pass("user://player_data.cfg",key)
	
	print("saved!")

func load()->void:
	var config = ConfigFile.new()
	var result =  config.load_encrypted_pass("user://player_data.cfg",key)
	if result == OK:
		Data.high = config.get_value("Score_Data","high_score")
	else:
		printerr("error on load")

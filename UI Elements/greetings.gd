extends Control

func _ready():
	var username = UserData.username if UserData.username != "" else "User"
	
	var time_dict = Time.get_datetime_dict_from_system(false)
	var hour = time_dict["hour"]
	
	var greeting = ""
	if hour < 12:
		greeting = "Good morning"
	elif hour < 18:
		greeting = "Good afternoon"
	else:
		greeting = "Good evening"
	
	%GreetingsLabel.text = greeting + " " + username + "!"

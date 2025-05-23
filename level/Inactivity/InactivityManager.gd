extends Node
signal plant_state_changed(new_state)

var current_state: String = "healthy"   #Current plant state
var last_login_time: int = 0           #Stored last login timestamp in Unix time

#Sets the last login time and determine initial plant state before game starts
func set_last_login_time(timestamp):
	last_login_time = timestamp
	var now = Time.get_unix_time_from_system()
	var diff = now - last_login_time
	#Determines initial state based on how long the user was away
	var new_state = "healthy"
	if diff > 48 * 3600:
		new_state = "dying"
	elif diff > 24 * 3600:
		new_state = "unhealthy"
	else:
		new_state = "healthy"
	current_state = new_state
	#Emits signal so PlantScene can update immediately
	emit_signal("plant_state_changed", current_state)

#Allows external call to water the plant (reset to healthy state immediately)
func water_plant():
	current_state = "healthy"
	emit_signal("plant_state_changed", current_state)

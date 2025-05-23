extends PanelContainer

var PARENT_COLLECTION_ID = "userInfo"
var SUBCOLLECTION_ID = "user_activity"

func _ready() -> void:
	$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Date.text = get_custom_date_string()
	$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Month.select(int(Time.get_date_dict_from_system(false)["month"]-1))
	$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Hour.select(Time.get_time_dict_from_system(false)["hour"])
	$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Minute.text = str(Time.get_time_dict_from_system(false)["minute"])

func _on_cancel_button_pressed():
	get_tree().change_scene_to_file("res://level/addActivity/ActivityOverlook.tscn")

func _on_submit_button_pressed():
	$PanelContainer2.visible = true
	
	var activity = %EditNameActivity.text
	if activity.is_empty():
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Please fill in activity name"
		return
	
	var typeActivity = %OptionActivity.text

	var activityDescription = %ActivityDescription.text
	
	var activityDate = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Date.text
	if activityDate.is_empty():
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Please fill in date to do activity"
		return
		
	var activityMonthID = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Month.get_selected_id()
	var activityMonth = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Month.text
	if int(activityMonthID) < int(Time.get_date_dict_from_system(false)["month"]-1):
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Month invalid"
		return
		
	if int(activityMonthID) == int(Time.get_date_dict_from_system(false)["month"]-1):
		if int(activityDate) < int(Time.get_date_dict_from_system(false)["day"]):
			$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Date invalid"
			return
	
	if int(activityDate) <= 0:
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Date invalid"
		return
		
	if int(activityDate) > 31: #DETTE GAELDER IKKE I ALLE MAANEDER
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Date invalid"
		return
		
	var activityTimeHour = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Hour.text
	var activityTimeMinute = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Minute.text

	if int(activityDate) == int(Time.get_date_dict_from_system(false)["day"]):
		if int(activityTimeHour) < int(Time.get_time_dict_from_system(false)["hour"]-1):
			$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Hour invalid"
			return
		if int(activityTimeHour) == int(Time.get_time_dict_from_system(false)["hour"]-1):
			if int(activityTimeMinute) < int(Time.get_time_dict_from_system(false)["minute"]+10):
				$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Minute invalid"
				return
	
	var activityTime = activityTimeHour + ":" + activityTimeMinute
	
	var timeToDoActivity = %numberForActivityTime.text
	if (timeToDoActivity == ""):
		timeToDoActivity = str(1)
	var typeofTimeToDoActivity = %typeForActivityTime.text
	timeToDoActivity = timeToDoActivity + " " + typeofTimeToDoActivity
	
	var optionRepeat = %OptionRepeat.text
	
	var auth = UserData.current_auth
	if auth == null or not auth.localid:
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "User not logged in!"
		return
	
	await save_activity(auth, activity, typeActivity, activityDescription, activityMonth, activityDate, activityTime, timeToDoActivity, optionRepeat)
	get_tree().change_scene_to_file("res://level/addActivity/ActivityOverlook.tscn")
	
func get_custom_date_string() -> String:
	#Get the date as a dictionary
	var date_dict = Time.get_date_dict_from_system(false)
	#Convert the day into a string
	var day_str = str(date_dict["day"])
	
	return day_str

func get_custom_month_string() -> String:
	#Get the date as a dictionary
	var date_dict = Time.get_date_dict_from_system(false)
		#Array with months
	var month_names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]
	#Get the month from the number
	var month_str = month_names[ date_dict["month"] - 1 ]
	return month_str

func get_custom_min_string() -> String:
	#Get the time as a dictionary
	var time_dict = Time.get_time_dict_from_system(false)
	#var hour_str = str(time_dict["hour"])
	var min_str = time_dict["minute"]

	if min_str < 10:
		min_str = "0" + str(min_str)
	
	return str(min_str)
	
func save_activity(auth, activity, typeActivity, activityDescription, activityMonth, activityDate, activityTime, timeToDoActivity, optionRepeat):
	#Creating Firestore Subcollection path
	var subcollection_path = PARENT_COLLECTION_ID + "/" + auth.localid + "/" + SUBCOLLECTION_ID
	var subcollection = Firebase.Firestore.collection(subcollection_path)
	
	var date_str = Time.get_date_string_from_system(false)
	var time_str = Time.get_time_string_from_system(false)
	time_str = time_str.replace(":", "-")
	
	var document_id = "Activity" + date_str + "_" + time_str + "_"
	
	var data = {
		"activity": activity,
		"typeActivity": typeActivity,
		"activityDescription": activityDescription,
		"activityMonth": activityMonth,
		"activityDate": str(activityDate),
		"activityTime": activityTime,
		"timeToDoActivity": timeToDoActivity,
		"optionRepeat": optionRepeat,
		"userID": auth.localid,
		"activityID": document_id
	}
	var new_doc
	new_doc = await subcollection.add(document_id, data)
	
	if optionRepeat != "No" :
		var date_array = []
		var next_activity_date = int(activityDate)
		
		if optionRepeat == "Daily" :
			for n in 6:
				next_activity_date += 1
				if next_activity_date > 31:
					next_activity_date = 1
					activityMonth = next_month(activityMonth)
				date_array.append(next_activity_date)
				
		if optionRepeat == "Weekly" :
			for n in 2: 
				next_activity_date += 7
				if next_activity_date > 31:
					next_activity_date = (next_activity_date-31)+1
					activityMonth = next_month(activityMonth)
				date_array.append(next_activity_date)
		
		if optionRepeat == "Every two weeks" :
			for n in 1: 
				next_activity_date += 14
				if next_activity_date > 31:
					next_activity_date = (next_activity_date-31)+1
					activityMonth = next_month(activityMonth)
				date_array.append(next_activity_date)
				
		if optionRepeat == "Monthly" :
			for n in 1: 
				next_activity_date += 30
				if next_activity_date > 31:
					next_activity_date = (next_activity_date-31)+1
					activityMonth = next_month(activityMonth)
				date_array.append(next_activity_date)
		
		for n in date_array.size():
			var copy = str(n+1)
			data = {
				"activity": activity,
				"typeActivity": typeActivity,
				"activityDescription": activityDescription,
				"activityMonth": activityMonth,
				"activityTime": activityTime,
				"timeToDoActivity": timeToDoActivity,
				"optionRepeat": optionRepeat,
				"userID": auth.localid,
				"activityDate": str(date_array[n]),
				"activityID": document_id,
				"repetitionCopy": copy
			}
			new_doc = await subcollection.add((document_id + "Copy" + copy), data)
	
	if new_doc:
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Saved successfully!"
	else:
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Failed to save successfully, try again."
	
func next_month(month):
	var month_names = [
			"January", "February", "March", "April", "May", "June",
			"July", "August", "September", "October", "November", "December"
					]
	var next_month_count
	for m in month_names.size():
		if month_names[m] == month:
			next_month_count = m + 1
			month = month_names[next_month_count]
			return month

extends PanelContainer

var PARENT_COLLECTION_ID = "userInfo"
var SUBCOLLECTION_ID_PRE = "previous_activity"
var SUBCOLLECTION_ID = "user_activity"

@onready var activityParentScene
@onready var clickedActivityID
var document_array = []

var todays_tasks = "res://MainScene.tscn"
var overlook_scene = "res://level/addActivity/ActivityOverlook.tscn"

#Long list of global variables that correspond to database fields
var activity_field
var activity_date_field
var activityDescription_field
var activityID_field
var activity_month_field
var time_field
var option_field
var timeToDoActivity_field
var typeActivity_field
var userID_field 

func _ready() -> void:		
	Firebase.Firestore.error.connect(Callable(self, "_on_firestore_error"))
	
	if UserData.current_auth == null or UserData.current_auth.localid == null:
		push_error("Brugeren er ikke autentificeret!")
		return
	
	var query: FirestoreQuery = FirestoreQuery.new()
	query.from("user_activity", true)  #Collection group query – Vi søger i alle "user_activity" subcollections for alle brugerne
	query.where("userID", FirestoreQuery.OPERATOR.EQUAL, UserData.current_auth.localid)
	query.where("activityID", FirestoreQuery.OPERATOR.EQUAL, clickedActivityID)

	var query_result = await Firebase.Firestore.query(query)
	if query_result == null:
		push_error("Query fejlede – query_result er null!")
		query_result = []
	
	var results: Array = query_result

	if results.size() > 0:
		for doc in results:
			#current_document = doc
			document_array.append(doc)
			activity_field = doc.get_value("activity")
			activity_date_field = doc.get_value("activityDate")
			activityDescription_field = doc.get_value("activityDescription")
			activityID_field = doc.get_value("activityID")
			activity_month_field = doc.get_value("activityMonth")
			time_field = doc.get_value("activityTime")
			option_field = doc.get_value("optionRepeat")
			timeToDoActivity_field = doc.get_value("timeToDoActivity")
			typeActivity_field = doc.get_value("typeActivity")
			userID_field = doc.get_value("userID")
			
			%EditNameActivity.set_text(activity_field)
			%OptionActivity.set_text(typeActivity_field)
			%ActivityDescription.set_text(activityDescription_field)
			if !(activity_month_field.is_empty()):
				var month_names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
				for m in range(month_names.size()):
					if month_names[m] == activity_month_field :
						$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Month.select(m)
			else:
				$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Month.select(int(Time.get_date_dict_from_system(false)["month"]-1))
			if !activity_date_field.is_empty():
				$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Date.set_text(activity_date_field)
			else:
				$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Date.text = get_custom_date_string()

			var time_array = str(time_field).split(":")	
			$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Hour.set_text(time_array[0])
			$PanelContainer/ColorRect/MarginContainer/VBoxContainer/TimeTo/HBoxContainer/Minute.set_text(time_array[1])
			
			var to_do_activity_time = str(timeToDoActivity_field).split(" ")
			%numberForActivityTime.set_text(to_do_activity_time[0])
			%typeForActivityTime.set_text(to_do_activity_time[1])
			%OptionRepeat.set_text(option_field)
	else:
		pass
			

func _on_cancel_button_pressed():
	queue_free()

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
	var typeofTimeToDoActivity = %typeForActivityTime.text
	timeToDoActivity = timeToDoActivity + " " + typeofTimeToDoActivity

	var optionRepeat = %OptionRepeat.text
	
	var auth = UserData.current_auth
	if auth == null or not auth.localid:
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "User not logged in!"
		return
		
	save_editted_activity(auth, activity, typeActivity, activityDescription, activityMonth, activityDate, activityTime, timeToDoActivity, optionRepeat)

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

#func get_custom_min_string() -> String:
	##Get the time as a dictionary
	#var time_dict = Time.get_time_dict_from_system(false)
	##var hour_str = str(time_dict["hour"])
	#var min_str = time_dict["minute"]
#
	#if min_str < 10:
		#min_str = "0" + str(min_str)
	#
	#return str(min_str)
	
func save_editted_activity(auth, activity, typeActivity, activityDescription, activityMonth, activityDate, activityTime, timeToDoActivity, optionRepeat):
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
		"activityID": document_id,
	}
	var updated_doc
	updated_doc = await subcollection.add(document_id, data)
	
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
			updated_doc = await subcollection.add((document_id + "Copy" + copy), data)
	
	for n in document_array.size():
		await subcollection.delete(document_array[n])
	
	if updated_doc:
		$PanelContainer/ColorRect/MarginContainer/VBoxContainer/ErrorLabel.text = "Saved successfully!"
		if activityParentScene == 1:
			get_tree().change_scene_to_file(todays_tasks)
		else:
			get_tree().change_scene_to_file(overlook_scene)
	
		queue_free()
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

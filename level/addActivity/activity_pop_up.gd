extends Control

var assigned_texture = null
var clickedActivityID
var passed_activity_name = ""
var passed_time = ""
var passed_description = ""
var passed_month = ""
var passed_date = ""

@onready var activityParentScene
@onready var activity_name_label: Label = $ColorRect/Control2/MarginContainer/HBoxContainer/VBoxContainer2/Activity
@onready var time_label: Label = $ColorRect/Control2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/TimeForActivity
@onready var description_label: RichTextLabel = $ColorRect/Control2/MarginContainer/HBoxContainer/VBoxContainer2/Description
@onready var type_texture_rect: TextureRect = $ColorRect/Control2/MarginContainer/HBoxContainer/TextureRect
@onready var month_label: Label = $ColorRect/Control2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/MonthLabel
@onready var date_label: Label = $ColorRect/Control2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/DateLabel
@onready var xp_node: Node = $XpGained
@onready var xp_anim: AnimationPlayer = xp_node.get_node("AnimationPlayer")

@onready var avoid_early_clicks: Timer = $Avoid_early_clicks

var current_document
var document_array = []
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

var todays_tasks = "res://MainScene.tscn"

var overlook_scene = "res://level/addActivity/ActivityOverlook.tscn"

const XP_PER_HOUR = 10
const MAX_XP_PER_TASK = 100
var xp_reward = 0

func _ready() -> void:
	
	avoid_early_clicks.timeout.connect(Callable(self, "_allow_clicks"))
	
	Firebase.Firestore.error.connect(Callable(self, "_on_firestore_error"))
	
	if assigned_texture:
		type_texture_rect.texture = assigned_texture
	#else:
		#print("Warning: No texture provided to activity_pop_up!")
	
	activity_name_label.text = passed_activity_name
	time_label.text = passed_time
	description_label.text = passed_description
	month_label.text = passed_month
	date_label.text = passed_date

	var query: FirestoreQuery = FirestoreQuery.new()
	query.from("user_activity", true)
	query.where("userID", FirestoreQuery.OPERATOR.EQUAL, UserData.current_auth.localid)
	query.where("activityID", FirestoreQuery.OPERATOR.EQUAL, clickedActivityID)
	
	var query_result = await Firebase.Firestore.query(query)
	if query_result == null:
		push_error("Query failed – query_result is null!")
		query_result = []
	var results: Array = query_result
	
	if results.size() > 0:
		current_document = results[0]
		for doc in results:
			current_document = doc
			document_array.append(doc)
			activity_field = current_document.get_value("activity")
			activity_date_field = current_document.get_value("activityDate")
			activityDescription_field = current_document.get_value("activityDescription")
			activityID_field = current_document.get_value("activityID")
			activity_month_field = current_document.get_value("activityMonth")
			time_field = current_document.get_value("activityTime")
			option_field = current_document.get_value("optionRepeat")
			timeToDoActivity_field = current_document.get_value("timeToDoActivity")
			typeActivity_field = current_document.get_value("typeActivity")
			userID_field = current_document.get_value("userID")
			
			activity_name_label.text = activity_field
			time_label.text = time_field
			description_label.text = activityDescription_field
			month_label.text = activity_month_field
			date_label.text = activity_date_field
			
			if activity_date_field == passed_date:
				break
	#else:
		#print("No activity details found for the given ID.")

	var parts = timeToDoActivity_field.split(" ")
	var num = 0
	if parts.size() >= 1:
		num = parts[0].to_int()
	var hours = 0
	var minutes = 0
	if parts.size() >= 2:
		var unit = parts[1].to_lower()
		if unit.begins_with("hour"):
			hours = num
		elif unit.begins_with("minute"):
			minutes = num
	var total_hours = float(hours) + float(minutes) / 60.0
	xp_reward = int(total_hours * XP_PER_HOUR)
	if xp_reward > MAX_XP_PER_TASK:
		xp_reward = MAX_XP_PER_TASK
	#print("Activity duration: ", hours, "h", minutes, "m -> XP reward (capped): ", xp_reward)
	
func _allow_clicks():
	$ColorRect/Control/HBoxContainer/DeleteActivity.disabled = false
	$ColorRect/Control/HBoxContainer/EditActivity.disabled = false
	$ColorRect/Control/HBoxContainer/CompletedActivity.disabled = false
	
	#$LoadingLabel.visible = false
	$ColorRect/Control/LoadingPanelContainer.visible = false
	$ColorRect/Control2/MarginContainer.visible = true
	
func _on_delete_activity_pressed() -> void:
	await save_to_previous_activity(
		UserData.current_auth,
		activity_field,
		typeActivity_field,
		activityDescription_field,
		activity_month_field,
		activity_date_field,
		time_field,
		timeToDoActivity_field,
		option_field,
		"deleted"
	)

	var subcollection_path = "userInfo/%s/user_activity" % UserData.current_auth.localid
	var subcollection = Firebase.Firestore.collection(subcollection_path)

	for doc in document_array:
		await subcollection.delete(doc)
	
	if activityParentScene == 1:
		get_tree().change_scene_to_file(todays_tasks)
	else:
		get_tree().change_scene_to_file(overlook_scene)
	
	queue_free()


func _on_edit_activity_pressed() -> void:
	var EditActivity_scene = preload("res://level/addActivity/editActivity.tscn")
	var edit_activity_item = EditActivity_scene.instantiate()		
	
	edit_activity_item.clickedActivityID = clickedActivityID
	edit_activity_item.activityParentScene = activityParentScene
	#edit_activity_item.passed_date = passed_date
	get_tree().root.add_child(edit_activity_item)
	queue_free()
	

func _on_completed_activity_pressed() -> void:
	xp_node.visible = true
	xp_anim.play("XPGained")

	await save_to_previous_activity(
		UserData.current_auth,
		activity_field,
		typeActivity_field,
		activityDescription_field,
		activity_month_field,
		activity_date_field,
		time_field,
		timeToDoActivity_field,
		option_field,
		"completed"
	)
	XpManager.add_xp(xp_reward)

	var subcollection_path = "userInfo/%s/user_activity" % UserData.current_auth.localid
	var subcollection = Firebase.Firestore.collection(subcollection_path)
	await subcollection.delete(current_document)
	
	if activityParentScene == 1:
		get_tree().change_scene_to_file(todays_tasks)
	else:
		get_tree().change_scene_to_file(overlook_scene)
	
	queue_free()

func _on_close_button_pressed() -> void:
	queue_free()
	
func save_to_previous_activity(auth, activity, typeActivity, activityDescription, activityMonth, activityDate, activityTime, timeToDoActivity, optionRepeat, activityStatus):
	var subcollection_path = "userInfo/" + auth.localid + "/previous_activity"
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
		"activityDate": activityDate,
		"activityTime": activityTime,
		"timeToDoActivity": timeToDoActivity,
		"optionRepeat": optionRepeat,
		"activityStatus": activityStatus,
		"userID": auth.localid,
		"activityID": document_id
	}
	
	var new_doc = await subcollection.add(document_id, data)
	
	#if new_doc:
		#print("Activity saved successfully with ID:", new_doc.doc_name)
	#else:
		#print("Failed to save activity")

func _on_firestore_error(error_info):
	for key in error_info.keys():
		print(key, ":", error_info[key])

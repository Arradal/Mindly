extends Control

@onready var activity_container: VBoxContainer = $VBoxContainer/RightSide/MarginContainer/VBoxContainer
var activityParentScene = 0

func _ready() -> void:
	Firebase.Firestore.error.connect(Callable(self, "_on_firestore_error"))
	
	if UserData.current_auth == null or UserData.current_auth.localid == null:
		push_error("Brugeren er ikke autentificeret!")
		return
	
	var query: FirestoreQuery = FirestoreQuery.new()
	query.from("user_activity", true)  #Collection group query – Vi søger i alle "user_activity" subcollections for alle brugerne
	query.where("userID", FirestoreQuery.OPERATOR.EQUAL, UserData.current_auth.localid)
	query.order_by("activityTime", FirestoreQuery.DIRECTION.ASCENDING)

	var query_result = await Firebase.Firestore.query(query)
	if query_result == null:
		push_error("Query fejlede – query_result er null!")
		query_result = []
	
	var results: Array = query_result
	#print("Query results: ", results)
	
	for child in activity_container.get_children():
		child.queue_free()
	
	var results_found = false
	if results.size() > 0:
		for doc in results:
			results_found = true
			var date_field = doc.get_value("activityDate")
			var month_field = doc.get_value("activityMonth")
			var time_field = doc.get_value("activityTime")
			var typeActivity_field = doc.get_value("typeActivity")
			var activity_field = doc.get_value("activity")
			var activityDescription_field = doc.get_value("activityDescription")
			var activityID_field = doc.get_value("activityID")
			
			var time_raw: String = ""
			if time_field is Dictionary and time_field.has("stringValue"):
				time_raw = time_field["stringValue"]
			else:
				time_raw = str(time_field)
				
			var activity_name: String = ""
			if activity_field is Dictionary and activity_field.has("stringValue"):
				activity_name = activity_field["stringValue"]
			else:
				activity_name = str(activity_field)
				
			var activityDescription_raw: String = ""
			if activityDescription_field is Dictionary and activityDescription_field.has("stringValue"):
				activityDescription_raw = activityDescription_field["stringValue"]
			else:
				activityDescription_raw = str(activityDescription_field)
				
			var activityItem_scene = preload("res://level/addActivity/ActivityItem.tscn")
			var activity_item = activityItem_scene.instantiate()
			
			activity_container.add_child(activity_item)
			
			activity_item.mouse_filter = Control.MOUSE_FILTER_PASS
			var btn = activity_item.get_node("Button")
			btn.mouse_filter = Control.MOUSE_FILTER_PASS

			activity_item.clickedActivityID = activityID_field
			activity_item.activityParentScene = activityParentScene
				
			activity_item.set_activity_data(activity_name, time_raw, activityDescription_raw, typeActivity_field, month_field, date_field)
			
	if (results_found == false):
		var no_ref_label = Label.new()
		no_ref_label.text = "No activities yet!"
		no_ref_label.add_theme_color_override("font_color", Color.BLACK)
		activity_container.add_child(no_ref_label)
	
func _on_firestore_error(error_info):
	for key in error_info.keys():
		print(key, ":", error_info[key])

func text_month(month):
	var month_names = [
			"January", "February", "March", "April", "May", "June",
			"July", "August", "September", "October", "November", "December"
					]
	var text_month = month_names[month - 1]
	return text_month

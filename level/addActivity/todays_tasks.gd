extends Control

@onready var activity_container: VBoxContainer = $PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer
var popup_scene = preload("res://level/addActivity/activity_pop_up.tscn")
var activityParentScene = 1

func _ready() -> void:
	Firebase.Firestore.error.connect(Callable(self, "_on_firestore_error"))
	load_today_tasks()

func load_today_tasks() -> void:
	for child in activity_container.get_children():
		child.queue_free()

	var query: FirestoreQuery = FirestoreQuery.new()
	query.from("user_activity", true)
	query.where("userID", FirestoreQuery.OPERATOR.EQUAL, UserData.current_auth.localid)
	query.order_by("activityTime", FirestoreQuery.DIRECTION.ASCENDING)

	var query_result = await Firebase.Firestore.query(query)
	if query_result == null:
		push_error("Query fejlede – query_result er null!")
		query_result = []
	var results: Array = query_result

	var results_found = false
	var today = Time.get_date_dict_from_system(false)
	var today_day = str(today["day"])
	var today_month = text_month(today["month"])

	for doc in results:
		if doc.get_value("activityMonth") == today_month and doc.get_value("activityDate") == today_day:
			results_found = true

			# Instantiate the activity item
			var activityItem_scene = preload("res://level/addActivity/ActivityItem.tscn")
			var item = activityItem_scene.instantiate()
			activity_container.add_child(item)
			
			item.mouse_filter = Control.MOUSE_FILTER_PASS
			var btn = item.get_node("Button")
			btn.mouse_filter = Control.MOUSE_FILTER_PASS
			
			item.activityParentScene = activityParentScene

			item.clickedActivityID = doc.get_value("activityID")
			item.set_activity_data(
				_unwrap_string(doc.get_value("activity")),
				_unwrap_string(doc.get_value("activityTime")),
				_unwrap_string(doc.get_value("activityDescription")),
				_unwrap_string(doc.get_value("typeActivity")),
				_unwrap_string(doc.get_value("activityMonth")),
				_unwrap_string(doc.get_value("activityDate"))
			)

	if (results_found == false):
		var no_ref_label = Label.new()
		no_ref_label.text = "No activities for today, yet!"
		no_ref_label.add_theme_color_override("font_color", Color.BLACK)
		activity_container.add_child(no_ref_label)

func _on_activity_item_pressed(doc) -> void:
	var popup = popup_scene.instantiate()
	popup.set_activity_doc(doc)
	add_child(popup)
	popup.connect("activity_completed", Callable(self, "_on_activity_completed"))

func _on_activity_completed(completed_id) -> void:
	load_today_tasks()

func _on_firestore_error(error_info):
	for key in error_info.keys():
		print(key, ":", error_info[key])

func text_month(month):
	var month_names = [
		"January","February","March","April","May","June",
		"July","August","September","October","November","December"
	]
	return month_names[month - 1]

func _unwrap_string(field) -> String:
	if field is Dictionary and field.has("stringValue"):
		return field["stringValue"]
	return str(field)

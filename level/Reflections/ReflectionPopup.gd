extends Control

@export var selected_date: String = ""
@onready var reflections_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var chosen_date_label: Label = $PanelContainer/ColorRect/ChosenDate

var images = [
	preload("res://assets/Mood Icons/angry.png"),
	preload("res://assets/Mood Icons/cry.png"),
	preload("res://assets/Mood Icons/slightly_frowning_face.png"),
	preload("res://assets/Mood Icons/sleeping.png"),
	preload("res://assets/Mood Icons/neutral_face.png"),
	preload("res://assets/Mood Icons/slightly_smiling_face.png"),
	preload("res://assets/Mood Icons/smile.png")
]

var type_to_index = {
	"angry": 0,
	"sad": 1,
	"hurt": 2,
	"tired": 3,
	"bored": 4,
	"happy": 5,
	"very happy": 6
}

func _ready() -> void:
	chosen_date_label.text = format_date(selected_date)
	
	Firebase.Firestore.error.connect(Callable(self, "_on_firestore_error"))
	
	if UserData.current_auth == null or UserData.current_auth.localid == null:
		push_error("Brugeren er ikke autentificeret!")
		return

	var query: FirestoreQuery = FirestoreQuery.new()
	query.from("dailyReflections", true)  #Collection group query (Her søger vi i alle reflections subcollections)
	query.where("userID", FirestoreQuery.OPERATOR.EQUAL, UserData.current_auth.localid)
	query.order_by("time", FirestoreQuery.DIRECTION.ASCENDING)

	
	var query_result = await Firebase.Firestore.query(query)
	if query_result == null:
		push_error("Query fejlede – query_result er nil!")
		query_result = []  #Fallback til et tomt array
	
	var results: Array = query_result
	
	for child in reflections_container.get_children():
		child.queue_free()
	
	var results_found = false
	if results.size() > 0:
		for doc in results:
			var date_field = doc.get_value("date")
			if (date_field == selected_date):
				results_found = true
				var time_field = doc.get_value("time")
				var reflection_field = doc.get_value("reflection")
				var mood_field = doc.get_value("mood")
					
					
				var time_raw: String = ""
				if time_field is Dictionary and time_field.has("stringValue"):
					time_raw = time_field["stringValue"]
				else:
					time_raw = str(time_field)
					var formatted_time: String = time_raw.replace("-", ":")
					var time_parts = formatted_time.split(":")
					if time_parts.size() >= 2:
						formatted_time = time_parts[0] + ":" + time_parts[1]
					
					var reflection_text: String = ""
					if reflection_field is Dictionary and reflection_field.has("stringValue"):
						reflection_text = reflection_field["stringValue"]
					else:
						reflection_text = str(reflection_field)
					
					var mood_text: String = ""
					if mood_field is Dictionary and mood_field.has("stringValue"):
						mood_text = mood_field["stringValue"]
					else:
						mood_text = str(mood_field)
					
					var reflection_scene = preload("res://level/Reflections/ReflectionItem.tscn")
					var reflection_item = reflection_scene.instantiate()
					
					#Her tilføjer vi først ReflectionItem til containeren, så kører vi _ready() og sætter vores onready-variabler
					reflections_container.add_child(reflection_item)
							
					reflection_item.mouse_filter = Control.MOUSE_FILTER_PASS
					var container = reflection_item.get_node("VBoxContainer/PanelContainer")
					container.mouse_filter = Control.MOUSE_FILTER_PASS
					
					reflection_item.time_label.text = formatted_time
					reflection_item.reflection_label.text = reflection_text
					reflection_item.mood_label.text = mood_text
	if results_found == false:
		$PanelContainer/ColorRect/NoReflections.text = "No reflections for this day"



func format_date(date_str: String) -> String:
	var parts = date_str.split("-")
	if parts.size() < 3:
		return date_str
	var year = parts[0]
	var month_number = int(parts[1])
	var day = parts[2]
	var month_names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]
	var month_name = month_names[month_number - 1]
	return month_name + " " + day + ", " + year

func _on_firestore_error(error_info):
	for key in error_info.keys():
		print(key, ":", error_info[key])

func _on_close_button_pressed() -> void:
	queue_free()

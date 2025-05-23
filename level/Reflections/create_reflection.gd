extends Control

var PARENT_COLLECTION_ID = "userInfo"
var SUBCOLLECTION_ID = "dailyReflections"

var images = [
	preload("res://assets/Mood Icons/angry.png"),
	preload("res://assets/Mood Icons/cry.png"),
	preload("res://assets/Mood Icons/slightly_frowning_face.png"),
	preload("res://assets/Mood Icons/sleeping.png"),
	preload("res://assets/Mood Icons/neutral_face.png"),
	preload("res://assets/Mood Icons/slightly_smiling_face.png"),
	preload("res://assets/Mood Icons/smile.png")
]

var moods = ["angry", "sad", "hurt", "tired", "bored", "happy", "very happy"]
var current_mood = ""

func _ready():
	$MarginContainer/VBoxContainer/VBoxContainer/HSlider.value = 50
	$MarginContainer/VBoxContainer/VBoxContainer/HSlider.value_changed.connect(Callable(self, "_on_h_slider_value_changed"))
	_on_h_slider_value_changed($MarginContainer/VBoxContainer/VBoxContainer/HSlider.value)
	
	%CurrentDateLabel.text = get_custom_date_string()

func _on_save_button_pressed():
	var reflection = $MarginContainer/VBoxContainer/VBoxContainer2/MarginContainer/TextEdit.text
	if reflection.is_empty():
		$MarginContainer/VBoxContainer/VBoxContainer2/Label3.text = "Please fill in your reflection"
		return
	
	var auth = UserData.current_auth
	if auth == null or not auth.localid:
		$MarginContainer/VBoxContainer/VBoxContainer2/Label3.text = "User not logged in!"
		return
	
	$MarginContainer/VBoxContainer/VBoxContainer2/Label3.text = "Saving reflection..."
	save_reflection(auth, reflection, current_mood)

func _on_h_slider_value_changed(value: float):
	var image_count = images.size()
	var index = int(value / (100.0 / image_count))
	index = clamp(index, 0, image_count - 1)
	$MarginContainer/VBoxContainer/VBoxContainer/TextureRect.texture = images[index]
	current_mood = moods[index]
	
func _on_cancel_button_pressed():
	get_tree().change_scene_to_file("res://level/Reflections/Calendar.tscn")
	
func get_custom_date_string() -> String:
	var date_dict = Time.get_date_dict_from_system(false)
	var month_names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]
	var day_str = str(date_dict["day"])
	var month_str = month_names[ date_dict["month"] - 1 ]
	var year_str = str(date_dict["year"])
	return month_str + " " + day_str + ", " + year_str
	

func save_reflection(auth, reflection, mood):
	var subcollection_path = PARENT_COLLECTION_ID + "/" + auth.localid + "/" + SUBCOLLECTION_ID
	var subcollection = Firebase.Firestore.collection(subcollection_path)
	
	var date_str = Time.get_date_string_from_system(false)
	var time_str = Time.get_time_string_from_system(false)
	time_str = time_str.replace(":", "-")
	
	var random_number = str(randi() % 1000)
	var document_id = "Reflection_" + date_str + "_" + time_str + "_" + random_number
	
	var data = {
		"reflection": reflection,
		"mood": mood,
		"date": date_str,
		"time": time_str,
		"userID": auth.localid  #Vigtigt! Tilføjer UID her, så vi kan filtrere på det i vores query
	}
	
	var new_doc = await subcollection.add(document_id, data)
	
	if new_doc:
		print("Reflection saved successfully with ID:", new_doc.doc_name)
		$MarginContainer/VBoxContainer/VBoxContainer2/Label3.text = "Saved successfully!"
		get_tree().change_scene_to_file("res://level/Reflections/Calendar.tscn")
	else:
		print("Failed to save reflection")
		$MarginContainer/VBoxContainer/VBoxContainer2/Label3.text = "Failed to save reflection"

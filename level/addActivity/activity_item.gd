extends Control

@onready var clickedActivityID
@onready var activityParentScene
@onready var activity_pic: TextureRect = $Button/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/TypeOfActivityPic
@onready var activity_name_label: Label = $Button/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/ActivityName
@onready var time_label: Label = $Button/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/HBoxContainer/TimeForActivity
@onready var description_label: RichTextLabel = $Button/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/Description
@onready var month_label: Label = $Button/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/HBoxContainer/MonthLabel
@onready var date_label: Label = $Button/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/HBoxContainer/DateLabel

var assigned_texture = null
var type_to_index = {
	"Physical": 0,
	"Psychological": 1,
	"Social": 2,
	"Leisure": 3,
	"Spiritual": 4,
	"Other": 5
}
var images = [
	preload("res://assets/Tasks Icons/muscle.png"),
	preload("res://assets/Tasks Icons/thinking_face.png"),
	preload("res://assets/Tasks Icons/heartbeat.png"),
	preload("res://assets/Tasks Icons/relieved.png"),
	preload("res://assets/Tasks Icons/raised_hands.png"),
	preload("res://assets/Tasks Icons/woman-tipping-hand.png")
]

func set_activity_data(activity_name: String, time_str: String, description: String, type_activity: String, month: String, date) -> void:
	date = str(date)
	
	activity_name_label.text = activity_name
	time_label.text = time_str
	description_label.text = description
	date_label.text = date
	month_label.text = month

	var image_index = type_to_index.get(type_activity, type_to_index["Other"])
	assigned_texture = images[image_index]
	activity_pic.texture = assigned_texture
	


func _on_button_pressed() -> void:
	var popup_scene = preload("res://level/addActivity/activity_pop_up.tscn")
	var popup = popup_scene.instantiate()
	popup.clickedActivityID = clickedActivityID
	popup.activityParentScene = activityParentScene
	popup.assigned_texture = assigned_texture
	popup.passed_activity_name = activity_name_label.text
	popup.passed_time = time_label.text
	popup.passed_description = description_label.text
	popup.passed_date = date_label.text
	popup.passed_month = month_label.text
	get_tree().current_scene.add_child(popup)

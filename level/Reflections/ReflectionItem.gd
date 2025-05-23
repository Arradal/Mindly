extends Control

#@onready var time_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer3/VBoxContainer/HBoxContainer/Timestamp
#@onready var mood_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer3/VBoxContainer/HBoxContainer2/Mood
#@onready var reflection_label: RichTextLabel = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/Reflection
#@onready var type_texture_rect: TextureRect = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer3/TextureRect

@onready var time_label: Label = $VBoxContainer/PanelContainer/VBoxContainer2/Timestamp
@onready var mood_label: Label = $VBoxContainer/PanelContainer/VBoxContainer2/Mood
@onready var reflection_label: RichTextLabel = $VBoxContainer/PanelContainer/VBoxContainer2/Reflection
@onready var type_texture_rect: TextureRect = $VBoxContainer/PanelContainer/VBoxContainer2/TextureRect

#func _ready() -> void:
	#print("ReflectionItem ready. Time label:", time_label, "Mood label:", mood_label, "Reflection label:", reflection_label)

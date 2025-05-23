extends Control

func _on_create_activity_pressed() -> void:

	get_tree().change_scene_to_file("res://level/addActivity/addActivity.tscn")

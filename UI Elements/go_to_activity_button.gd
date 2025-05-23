extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://level/addActivity/ActivityOverlook.tscn")

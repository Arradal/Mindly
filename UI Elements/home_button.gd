extends Control


#func _on_go_to_activity_pressed() -> void:
	#get_tree().change_scene_to_file("res://level/addActivity/ActivityOverlook.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MainScene.tscn")

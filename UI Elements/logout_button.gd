extends Control

func _on_texture_button_pressed():
	Firebase.Auth.logout()
	var logging_out_scene = load("res://UI Elements/LoggingOut.tscn").instantiate()
	get_tree().current_scene.add_child(logging_out_scene)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://level/Login/Authentication.tscn")

extends Control

var COLLECTION_ID = "userInfo"

func _ready():
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)

func _on_login_button_pressed():
	var email = $VBoxContainer/VBoxContainer2/MarginContainer/LineEditUsername.text + "@mail.com"
	var password = %LineEditPassword.text

	if email.is_empty() or password.is_empty():
		%StateLabel.text = "Please enter both username and password"
		return

	Firebase.Auth.login_with_email_and_password(email, password)
	%StateLabel.text = "Logging in..."

func on_login_succeeded(auth):
	%StateLabel.text = "Login success!"
	
	UserData.current_auth = auth
	Firebase.Auth.save_auth(auth)

	get_tree().change_scene_to_file("res://UI Elements/Loading.tscn")

func on_login_failed(_error_code, _message):
	%StateLabel.text = "Login failed"
	%StateLabel2.text = "Check Username or Password"

func _on_create_account_button_pressed() -> void:
	get_tree().change_scene_to_file("res://level/Create Account/Signup.tscn")

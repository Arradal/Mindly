extends Control

var COLLECTION_ID = "userInfo"

func _ready():
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.signup_failed.connect(on_signup_failed)

func _on_signup_button_pressed():
	var email = %NameLineEdit.text + "@mail.com"
	var password = %PasswordLineEdit.text
	var username = %NameLineEdit.text
	var max_chars = 12
	var min_chars_password = 6
	
	if username.length() > max_chars:
		%StateLabel.text = "Username too long"
		%StateLabel2.text = "Maximum %d characters!" % max_chars
		return
	
	if password.length() < min_chars_password:
		%StateLabel.text = "Password too short"
		%StateLabel2.text = "Minimum %d characters required!" % min_chars_password
		return
	
	if email.is_empty() or password.is_empty() or username.is_empty():
		%StateLabel.text = "Please fill in all fields"
		return
		
	if not is_valid_email(email):
		%StateLabel.text = "Check Username"
		%StateLabel2.text = "Use only letters and numbers"
		return
	
	if not is_valid_password(password):
		%StateLabel.text = "Check Password"
		%StateLabel2.text = "Use only letters and numbers"
		return
	
	Firebase.Auth.signup_with_email_and_password(email, password)
	%StateLabel.text = "Signing up..."
	%StateLabel2.text = "Please wait..."

func on_signup_succeeded(auth):
	%StateLabel.text = "Sign up success!"
	UserData.current_auth = auth
	Firebase.Auth.save_auth(auth)
	await save_data(auth)
	await get_user_info(auth)

	get_tree().change_scene_to_file("res://MainScene.tscn")

func on_signup_failed(error_code, message):
	%StateLabel.text = "Sign up failed"

func save_data(auth):
	if auth.localid:
		var collection = Firebase.Firestore.collection(COLLECTION_ID)
		var username = %NameLineEdit.text
		var current_time = Time.get_unix_time_from_system()
		var player_level = "1"
		var player_xp = "0"
		var data = {
			"user_name": username,
			"email": auth.email,
			"last_login_time": current_time,
			"player_level": player_level,
			"player_xp": player_xp
		}

		#Check if document already exists
		var document = await collection.get_doc(auth.localid)

		if document and not document.is_null_value("user_name"):
			#If it exists, update it
			document.add_or_update_field("user_name", username)
			document.add_or_update_field("email", auth.email)
			document.add_or_update_field("last_login_time", current_time)

			var update_task = await collection.update(document)
			if update_task:
				print("User profile updated successfully")
			else:
				print("Failed to update user profile")
		else:
			#If it does not exists, create a new document
			var new_doc = await collection.add(auth.localid, data)
			if new_doc:
				print("User profile created successfully with ID:", new_doc.doc_name)
			else:
				print("Failed to create user profile")

func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	#This regex matches a standard email-format
	var pattern = "^[A-Za-z0-9]+@[A-Za-z0-9]+\\.[A-Za-z]{2,}$"
	if regex.compile(pattern) != OK:
		print("Error compiling of regex!")
		return false
	return regex.search(email) != null

func is_valid_password(password: String) -> bool:
	var regex = RegEx.new()
	var pattern = "^[A-Za-z0-9]+$"
	if regex.compile(pattern) != OK:
		print("Error compiling of regex!", regex)
		return false
	return regex.search(password) != null

func get_user_info(auth): #Now also retrieves the users name on login
	if auth == null:
		push_error("Failed to retrieve user info from firebase")
		return

	if auth.localid:
		var collection: FirestoreCollection = Firebase.Firestore.collection(COLLECTION_ID)
		var current_time = Time.get_unix_time_from_system()
		
		#Retrieve the user's document from Firestore
		var document = await collection.get_doc(auth.localid)
		print("Retrieved document:", document)
		
		if document:
			if "user_name" in document:
				UserData.username = document["user_name"]
			else:
				print("'user_name' field not found in document")
				UserData.username = "User"
			#Attempt to retrieve the last_login_time from the document
			var last_login_time = null
			if "last_login_time" in document:
				last_login_time = document["last_login_time"]
			if last_login_time == null:
				push_error("No last_login_time found in user info")
			else:
				print("Firebase last login time: %s" % str(last_login_time))
				if get_node_or_null("/root/InactivityManager"):
					get_node("/root/InactivityManager").set_last_login_time(last_login_time)
				else:
					push_error("InactivityManager not found, cannot initialize plant state")
			
			#Update the document with the current time
			document.add_or_update_field("last_login_time", current_time)
			var update_task = await collection.update(document)
			if update_task:
				print("User last login time updated successfully")
			else:
				print("Failed to update last login time")
		else:
			print("User document does not exist. Consider creating it or handling this error accordingly.")

func _on_back_to_login_button_pressed():
	get_tree().change_scene_to_file("res://level/Login/Authentication.tscn")

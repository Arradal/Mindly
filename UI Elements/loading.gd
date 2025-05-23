extends Control

@export var loading_bar: ProgressBar

var scene_path: String = "res://MainScene.tscn"

var progress: Array = []
var total_steps: int = 5
var firebase_steps_done: int = 0

func _ready() -> void:
	scene_path = "res://MainScene.tscn"
	ResourceLoader.load_threaded_request(scene_path, "", false)
	call_deferred("start_firebase_tasks")

func _process(delta: float) -> void:
	ResourceLoader.load_threaded_get_status(scene_path, progress)
	var scene_progress: float = 0.0
	if progress.size() > 0:
		scene_progress = progress[0]
		
	var overall_progress: float = (firebase_steps_done + scene_progress) / float(total_steps)
	loading_bar.value = lerp(loading_bar.value, overall_progress * 100.0, delta * 2.0)
	
	if overall_progress >= 1.0:
		var next_scene = ResourceLoader.load_threaded_get(scene_path)
		get_tree().change_scene_to_packed(next_scene)

func start_firebase_tasks() -> void:
	await update_last_login(UserData.current_auth)
	firebase_steps_done += 1
	
	await load_player_level_from_firestore()
	firebase_steps_done += 1
	
	await load_player_xp_from_firestore()
	firebase_steps_done += 1
	
	await load_user_rewards_from_firestore()
	firebase_steps_done += 1

	XpManager.level = UserData.level
	XpManager.xp = UserData.player_xp
	firebase_steps_done += 1

func update_last_login(auth):
	if auth == null:
		push_error("Failed to retrieve user info from firebase")
		return

	if auth.localid:
		var collection: FirestoreCollection = Firebase.Firestore.collection("userInfo")
		var current_time = Time.get_unix_time_from_system()
		
		var document = await collection.get_doc(auth.localid)
		
		if document:
			var doc_data = {}
			if document.has_method("get_data"):
				doc_data = document.get_data()
			else:
				doc_data = document
			
			var times_logged_in_before = int(doc_data["times_logged_in"]) if "times_logged_in" in doc_data else 0
			var times_logged_in = times_logged_in_before + 1
			
			if "user_name" in doc_data:
				UserData.username = doc_data["user_name"]
			else:
				UserData.username = "User"
				
			var last_login_time = null
			
			if "last_login_time" in doc_data:
				last_login_time = doc_data["last_login_time"]
				
			#if last_login_time == null:
				#push_error("No last_login_time found in user info")
			#else:
				#print("Firebase last login time: %s" % str(last_login_time))
				
				if get_node_or_null("/root/InactivityManager"):
					get_node("/root/InactivityManager").set_last_login_time(last_login_time)
				else:
					push_error("InactivityManager not found, cannot initialize plant state")
			
			document.add_or_update_field("times_logged_in", times_logged_in)
			document.add_or_update_field("last_login_time", current_time)
			
			var update_task = await collection.update(document)
			
			#if update_task:
				#print("User last login time updated successfully")
			#else:
				#print("Failed to update last login time")
		#else:
			#print("User document does not exist. Consider creating it or handling this error accordingly.")

func load_player_level_from_firestore() -> void:
	if UserData.current_auth == null:
		push_error("User not authenticated; can't load level from Firestore")
		return

	var user_id = UserData.current_auth.localid
	var collection: FirestoreCollection = Firebase.Firestore.collection("userInfo")
	var document = await collection.get_doc(user_id)
	
	if document:
		var doc_data = {}
		if document.has_method("get_data"):
			doc_data = document.get_data()
		else:
			doc_data = document
		if "player_level" in doc_data:
			UserData.level = int(doc_data["player_level"])
			#print("Firestore: Loaded player level: ", UserData.level)
		#else:
			#print("Firestore: 'player_level' field not found. Using default level.")
	#else:
		#print("Firestore: User document not found")

func load_player_xp_from_firestore() -> void:
	if UserData.current_auth == null:
		push_error("User not authenticated; can't load XP from Firestore")
		return

	var user_id = UserData.current_auth.localid
	var col = Firebase.Firestore.collection("userInfo")
	var document: FirestoreDocument = await col.get_doc(user_id)
	var doc_data: Dictionary = {}
	
	if document.has_method("get_data"):
		doc_data = document.get_data()
	else:
		for key in document.keys():
			doc_data[key] = document.get_value(key)

	if doc_data.size() == 0:
		UserData.player_xp = 0
		return

	if doc_data.has("player_xp"):
		UserData.player_xp = int(doc_data["player_xp"])
	else:
		UserData.player_xp = 0


func load_user_rewards_from_firestore() -> void:
	if UserData.current_auth == null:
		push_error("User not authenticated; can't load rewards from Firestore")
		return

	var user_id = UserData.current_auth.localid
	var collection: FirestoreCollection = Firebase.Firestore.collection("userInfo")
	var document = await collection.get_doc(user_id)
	
	if document:
		var doc_data = {}
		if document.has_method("get_data"):
			doc_data = document.get_data()
		else:
			doc_data = document
			
		if "level_rewards" in doc_data:
			UserData.level_rewards = doc_data["level_rewards"]
		else:
			UserData.level_rewards = {}

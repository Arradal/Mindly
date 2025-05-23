extends CanvasLayer
var level_up_popup: PopupPanel
var is_level_changed_event_subscribed := false
var item_placeholder: Node2D
var selected_item := ""
var initial_load: bool = true
var level_items = {
	2: ["Book_shelf_Dark", "Book_shelf_Light"],
	3: ["Art_Dark", "Art_Light"],
	4: ["Window_Dark_2", "Window_Light_2"],
	5: ["Desk_Dark", "Desk_Light"],
	6: ["Chair_Dark", "Chair_Light"],
	7: ["Bed_Dark", "Bed_Light"],
	8: ["Lamp_Dark", "Lamp_Light"],
	9: ["Bord_Dark", "Bord_Light"],
	10: ["Radio_green", "Radio_Purple"]
}

var item_properties = {
	"Book_shelf_Dark": [Vector2(310, -102), Vector2(0.029, 0.029)],
	"Book_shelf_Light": [Vector2(310, -102), Vector2(0.029, 0.029)],
	"Art_Dark": [Vector2(63, -178),  Vector2(0.038, 0.038)],
	"Art_Light": [Vector2(63, -178),  Vector2(0.038, 0.038)],
	"Window_Dark_2": [Vector2(-56, -89),  Vector2(0.042, 0.042)],
	"Window_Light_2": [Vector2(-56, -89),  Vector2(0.042, 0.042)],
	"Desk_Dark": [Vector2(-179, 56),  Vector2(0.042, 0.042)],
	"Desk_Light": [Vector2(-179, 56),  Vector2(0.042, 0.042)],
	"Chair_Dark": [Vector2(-136, 62),  Vector2(0.029, 0.029)],
	"Chair_Light": [Vector2(-136, 62),  Vector2(0.029, 0.029)],
	"Bed_Dark": [Vector2(118, -36),  Vector2(0.048, 0.048)],
	"Bed_Light": [Vector2(118, -36),  Vector2(0.048, 0.048)],
	"Lamp_Dark": [Vector2(-82, -27),  Vector2(0.054, 0.054)],
	"Lamp_Light": [Vector2(-82, -27),  Vector2(0.054, 0.054)],
	"Bord_Dark": [Vector2(275, 15), Vector2(0.163, 0.163)],
	"Bord_Light": [Vector2(275, 15), Vector2(0.163, 0.163)],
	"Radio_green": [Vector2(279, -27), Vector2(0.077, 0.077)],
	"Radio_Purple": [Vector2(279, -27), Vector2(0.077, 0.077)],
	
	
}
var level_up_animation: Node
var anim_player: AnimationPlayer

var chair_scene: PackedScene = preload("res://scenes/furniture/chair.tscn")

func _ready():
	level_up_popup = $PopupPanel
	level_up_animation = $PopupPanel/VBoxContainer/LevelUpAnimation
	anim_player = level_up_animation.get_node("AnimationPlayer")
	
	if anim_player:
		anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
		
	item_placeholder = get_node("../ItemPlaceholder")
	
	if not is_level_changed_event_subscribed:
		XpManager.connect("level_changed", Callable(self, "_on_level_changed_event"))
		is_level_changed_event_subscribed = true
	update_popup_items(XpManager.level)
	$PopupPanel/VBoxContainer/HBoxContainer/TextureButton.pressed .connect(Callable(self, "on_item1_selected"))
	$PopupPanel/VBoxContainer/HBoxContainer/TextureButton2.pressed .connect(Callable(self, "on_item2_selected"))
	initial_load = false
	_process_pending_level_ups()
	
func _process_pending_level_ups() -> void:
	while UserData.pending_level_ups.size() > 0:
		var lvl = UserData.pending_level_ups.pop_front()
		update_popup_items(lvl)

func _on_level_changed_event(level: int):
	update_popup_items(level)
	
	
func update_popup_items(level: int):
	if UserData.level_rewards.has(str(level)):
		add_item_to_placeholder(UserData.level_rewards[str(level)])
		return
	if initial_load:
		return
	if level_items.has(level):
		var item1 = level_items[level][0]
		var item2 = level_items[level][1]
		var tex1 = load(get_texture_path(item1))
		var tex2 = load(get_texture_path(item2))
		var btn1 = $PopupPanel/VBoxContainer/HBoxContainer/TextureButton
		var btn2 = $PopupPanel/VBoxContainer/HBoxContainer/TextureButton2

		btn1.texture_normal = tex1
		btn2.texture_normal = tex2

		$PopupPanel/VBoxContainer/HBoxContainer.hide()
		level_up_popup.popup_centered()
		if anim_player:
			anim_player.play("LevelUp")
		else:
			$PopupPanel/VBoxContainer/HBoxContainer.show()


func _on_animation_finished(anim_name: String):
	if anim_name == "LevelUp":
		$PopupPanel/VBoxContainer/HBoxContainer.show()


func get_texture_path(item_name: String) -> String:
	return "res://assets/furniture/%s.png" % item_name


func on_item1_selected():
	var pet_level = XpManager.level
	if level_items.has(pet_level):
		selected_item = level_items[pet_level][0]
		UserData.level_rewards[str(pet_level)] = selected_item
		add_item_to_placeholder(selected_item)
		await update_rewards_in_firestore(UserData.level_rewards)
	level_up_popup.hide()
	
func on_item2_selected():
	var pet_level = XpManager.level
	if level_items.has(pet_level):
		selected_item = level_items[pet_level][1]
		UserData.level_rewards[str(pet_level)] = selected_item
		add_item_to_placeholder(selected_item)
		await update_rewards_in_firestore(UserData.level_rewards)
	level_up_popup.hide()
	
	
func update_rewards_in_firestore(rewards: Dictionary) -> void:
	if UserData.current_auth == null:
		push_error("User not authenticated; can't update rewards in Firestore")
		return

	var user_id = UserData.current_auth.localid
	var collection = Firebase.Firestore.collection("userInfo")
	var document = await collection.get_doc(user_id)

	var doc_data: Dictionary = {}
	if document and document.has_method("get_data"):
		doc_data = document.get_data()
	elif document:
		for key in document.keys():
			doc_data[key] = document.get_value(key)

	var existing_rewards: Dictionary = {}
	if doc_data.has("level_rewards"):
		existing_rewards = doc_data["level_rewards"]
	existing_rewards = existing_rewards.duplicate(true)

	for lvl_str in rewards.keys():
		existing_rewards[lvl_str] = rewards[lvl_str]

	document.add_or_update_field("level_rewards", existing_rewards)
	var success = await collection.update(document)
	if not success:
		push_error("Failed to update level_rewards in Firestore")
		
func add_item_to_placeholder(item_name: String):
	if item_placeholder == null:
		return
	var is_furniture = false
		
	if(item_name == "Chair_Light"):
		is_furniture = true
		var ChairInstance = chair_scene.instantiate() as Chair
		ChairInstance.identifier = 1
		
		var properties = item_properties[item_name]
		ChairInstance.position = properties[0]
		
		item_placeholder.add_child(ChairInstance)
		
	if (item_name == "Chair_Dark"):
		is_furniture = true
		var ChairInstance = chair_scene.instantiate() as Chair
		ChairInstance.identifier = 2
		
		var properties = item_properties[item_name]
		ChairInstance.position = properties[0]
		
		item_placeholder.add_child(ChairInstance)
	
	if(is_furniture == false):
		var item_texture = load(get_texture_path(item_name))
		if not item_texture:
			return
		var sprite = Sprite2D.new()
		sprite.texture = item_texture
		if item_properties.has(item_name):
			var properties = item_properties[item_name]
			sprite.position = properties[0]
			sprite.scale = properties[1]
		else:
			sprite.position = Vector2.ZERO
			sprite.scale = Vector2(0.5, 0.5)
		sprite.z_index = 1
		item_placeholder.add_child(sprite)

extends Area2D

const HEALTHY_TEXTURE = preload("res://scenes/PlantSprite/Snake_plant_1.png")
const UNHEALTHY_TEXTURE = preload("res://scenes/PlantSprite/Snake_plant_2.png")
const DYING_TEXTURE = preload("res://scenes/PlantSprite/Snake_plant_3.png")

var water_button_instance: Node2D = null
const WATER_BUTTON_SCENE: PackedScene = preload("res://level/Inactivity/WaterPlantButton.tscn")

@onready var sprite = $PlantSprite

func _ready():
	var inactivity_manager = get_node_or_null("/root/InactivityManager")
	if inactivity_manager:
		inactivity_manager.connect("plant_state_changed", Callable(self, "_on_plant_state_changed"))
		_on_plant_state_changed(inactivity_manager.current_state)
	else:
		push_error("InactivityManager node not found in scene tree")


func _on_plant_state_changed(new_state):
	match new_state:
		"healthy":
			sprite.texture = HEALTHY_TEXTURE
			if water_button_instance:
				water_button_instance.hide()
		"unhealthy":
			sprite.texture = UNHEALTHY_TEXTURE
			_ensure_water_button()
			if water_button_instance:
				water_button_instance.show()
		"dying":
			sprite.texture = DYING_TEXTURE
			_ensure_water_button()
			if water_button_instance:
				water_button_instance.show()
		_:
			push_error("Unknown plant state received: %s" % str(new_state))


func _ensure_water_button():
	if water_button_instance == null:
		water_button_instance = WATER_BUTTON_SCENE.instantiate() as Node2D
		add_child(water_button_instance)
		
		var button = water_button_instance.get_node("TextureButton") as TextureButton
		if button:
			button.connect("pressed", Callable(self, "_on_WaterPlantButton_pressed"))
			button.custom_minimum_size = Vector2(64, 64)
		else:
			push_error("TextureButton node not found inside WaterPlantButton scene")
		
		water_button_instance.position = sprite.position + Vector2(150, -1500)
		water_button_instance.hide()


func _on_WaterPlantButton_pressed():
	var inactivity_manager = get_node_or_null("/root/InactivityManager")
	if inactivity_manager:
		if inactivity_manager.has_method("water_plant"):
			inactivity_manager.water_plant()
		elif inactivity_manager.has_method("set_state"):
			inactivity_manager.set_state("healthy")
		else:
			inactivity_manager.emit_signal("plant_state_changed", "healthy")
		print("Player watered the plant. Plant state reset to healthy.")
	else:
		push_error("InactivityManager not found - cannot water plant")

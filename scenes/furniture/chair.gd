extends Area2D
class_name Chair

@export var interact_anim: String = "sit"

var light_chair: Texture2D
var dark_chair: Texture2D
var chair_sprite: Sprite2D

@onready var identifier

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	light_chair = load("res://assets/furniture/Chair_Light.png")
	dark_chair = load("res://assets/furniture/Chair_Dark.png")

	chair_sprite = $Chair as Sprite2D
	chair_sprite.scale = Vector2(0.029, 0.029)
	
	var _chair_interactBox = $interactibleDistance as CollisionShape2D
	
	if identifier == 1:
		chair_sprite.texture = light_chair
		interact_anim = "sit_light"
	elif identifier == 2:
		chair_sprite.texture = dark_chair
		interact_anim = "sit"

	connect("body_entered", Callable(self, "allow_interact"))
	connect("body_exited", Callable(self, "disallow_interact"))


#func Allow_interact(body: Node2D):
	#if body is Pet:
		#body.Allow_interact(self)
#
#func Disallow_interact(body: Node2D):
	#if body is Pet:
		#body.Disallow_interact()

func remove_chair():
	queue_free()

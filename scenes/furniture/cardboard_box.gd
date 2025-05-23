extends Area2D
class_name CardboardBox

# Interface implementation placeholder
# You can define IFurniture functionality in a base class or script if needed

@export var identifier: int = 1

var empty_box: Texture2D
var book_box: Texture2D
var plant_box: Texture2D
var _opened_box: Texture2D
var box_sprite: Sprite2D

func _ready():
	_opened_box = load("res://assets/furniture/Cardboard.png")
	empty_box = _opened_box

	box_sprite = $Cardboard as Sprite2D

	if identifier == 1:
		book_box = load("res://assets/furniture/Cardboard_books.png")
		box_sprite.texture = book_box
	elif identifier == 2:
		plant_box = load("res://assets/furniture/Cardboard_plant.png")
		box_sprite.texture = plant_box
	elif identifier == 3:
		plant_box = load("res://assets/furniture/Cardboard_plant.png")
		box_sprite.texture = plant_box

	connect("body_entered", Callable(self, "allow_interact"))
	connect("body_exited", Callable(self, "disallow_interact"))

#func allow_interact(body: Node2D):
#	if body is Pet:
#		body.allow_interact(self)

#func disallow_interact(body: Node2D):
#	if body is Pet:
#		body.disallow_interact()

func is_empty():
	box_sprite.texture = empty_box

func remove_box():
	visible = false
	#queue_free()

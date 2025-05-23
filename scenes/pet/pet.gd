extends CharacterBody2D
class_name Pet

signal level_changed_event(new_level: int)

@onready var _hitbox: CollisionShape2D = $CollisionShape2D
@onready var _petanimation: AnimatedSprite2D = $Pet_Animation
@onready var level_up_popup: PopupPanel = $"../CanvasLayer/PopupPanel"
@onready var xp_progress_bar: ProgressBar = $"../ProgressBar"
@onready var level_label: Label = $"../levelLabel"
@onready var _nav_agent: NavigationAgent2D = $NavAgent
@onready var _update_target_timer: Timer = $UpdateTargetTimer

var current_furniture: Node = null
#var previous_furniture
var amount_furniture: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var cardboard_box: CardboardBox = null
var cardboard_box2: CardboardBox = null
var cardboard_box3: CardboardBox = null

var Furniture = null
var AmAnimating = false

func _ready():
	var cur_xp = XpManager.xp
	var cur_lvl = XpManager.level
	var threshold = xp_needed_for_level(cur_lvl)

	xp_progress_bar.max_value = threshold
	xp_progress_bar.value = cur_xp
	level_label.text = "%d" % cur_lvl

	XpManager.connect("xp_changed",   Callable(self, "_on_xp_changed"))
	XpManager.connect("level_changed", Callable(self, "_on_level_changed"))

	_update_target_timer.timeout.connect(Callable(self, "update_target"))
	rng.randomize()
	update_target()
	
	level_up_popup.hide()

	for item in get_tree().get_nodes_in_group("furniture"):
		if item is CardboardBox:
			var my_box
			my_box = item
			if my_box.identifier == 1:
				cardboard_box = item
			elif my_box.identifier == 2:
				cardboard_box2 = item
			else:
				cardboard_box3 = item

	update_box_state()
	call_deferred("instantiate_saved_rewards")


func xp_needed_for_level(lvl: int) -> int:
	return 50 + (lvl - 1) * 50

func _on_xp_changed(new_xp: int) -> void:
	xp_progress_bar.value = new_xp

func _on_level_changed(new_level: int) -> void:
	level_label.text = "%d" % new_level

	var new_thresh = xp_needed_for_level(new_level)
	xp_progress_bar.max_value = new_thresh

	emit_signal("level_changed_event", new_level)
	show_level_up_popup()

	update_box_state()
	call_deferred("instantiate_saved_rewards")

func _process(_delta):
	if Input.is_action_just_pressed("level_up"):
		XpManager.add_xp(xp_needed_for_level(XpManager.level))

func _physics_process(_delta):
	move_towards_target()

func Interact_with_furniture():
	if  AmAnimating == false:
		AmAnimating = true
		
		if "interact_anim" in current_furniture:
			current_furniture.visible = false
			var anim_name = current_furniture.interact_anim
			_petanimation.play(anim_name)
			#previous_furniture = current_furniture
		else:
			_petanimation.play("idle")

func Uninteract_with_furniture():
	AmAnimating = false
	
	if current_furniture != null:
		if "interact_anim" in current_furniture:
				current_furniture.visible = true
		
	_petanimation.play("idle")

func move_towards_target():
	# don’t ask for a path until the map has at least one iteration
	var map_rid = _nav_agent.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return

	# now it’s safe
	var dir = global_position.direction_to(_nav_agent.get_next_path_position())
	var _next_pos = _nav_agent.get_next_path_position()
	if current_furniture: #and is_instance_valid(current_furniture):
		if global_position.distance_to(_nav_agent.get_next_path_position()) < 5.0:
			dir = Vector2.ZERO
	move(dir)

func move(dir: Vector2):
	velocity = dir * 200.0
	if velocity != Vector2.ZERO:
		_petanimation.play("walk")
		_petanimation.flip_h = velocity.x < 0
	else:
		if (current_furniture != null) and _nav_agent.target_position == current_furniture.global_position:	
			if "interact_anim" in current_furniture:
				_petanimation.flip_h = velocity.x < 0
			Interact_with_furniture()
		else:
			_petanimation.play("idle")
	move_and_slide()

func update_target():
	Uninteract_with_furniture()
	
	var group = get_tree().get_nodes_in_group("furniture")
	amount_furniture = group.size()
	if amount_furniture == 0:
		return

	var idx = rng.randi_range(0, amount_furniture - 1)
	current_furniture = group[idx]
	_nav_agent.target_position = current_furniture.global_position

func show_level_up_popup():
	level_up_popup.popup_centered()

func instantiate_saved_rewards():
	var keys = []
	for lvl_str in UserData.level_rewards.keys():
		keys.append(int(lvl_str))
	keys.sort()
	for lvl_int in keys:
		if lvl_int <= XpManager.level:
			var item = UserData.level_rewards[str(lvl_int)]
			get_node("../CanvasLayer").add_item_to_placeholder(item)

func update_box_state():
	var lvl = XpManager.level

	#Box 1
	if lvl >= 2 and is_instance_valid(cardboard_box) and cardboard_box.identifier == 1:
		cardboard_box.is_empty()
	if lvl >= 3 and is_instance_valid(cardboard_box):
		cardboard_box.remove_box()
		cardboard_box = null

	#Box 2
	if lvl >= 3 and is_instance_valid(cardboard_box2) and cardboard_box2.identifier == 2:
		cardboard_box2.is_empty()
	if lvl >= 4 and is_instance_valid(cardboard_box2):
		cardboard_box2.remove_box()
		cardboard_box2 = null
	
	#Box 3
	if lvl >= 4 and is_instance_valid(cardboard_box3) and cardboard_box3.identifier == 3:
		cardboard_box3.is_empty()
	if lvl >= 5 and is_instance_valid(cardboard_box3):
		cardboard_box3.remove_box()
		cardboard_box3 = null

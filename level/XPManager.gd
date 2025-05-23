extends Node

signal xp_changed(new_xp)
signal level_changed(new_level)

var xp: int = 0
var level: int = 1

func _ready() -> void:
	xp = UserData.player_xp
	level = UserData.level

func add_xp(amount: int) -> void:
	xp += amount
	emit_signal("xp_changed", xp)
	_try_level_up()
	_sync_to_firestore()

func _try_level_up() -> void:
	var needed = xp_needed_for_level(level)
	if xp >= needed:
		xp -= needed
		level += 1
		UserData.pending_level_ups.append(level)
		emit_signal("level_changed", level)

func xp_needed_for_level(lvl: int) -> int:
	return 30 + (lvl - 1) * 25

func _sync_to_firestore() -> void:
	if UserData.current_auth == null:
		push_error("XPManager: Not authenticated; can't sync to Firestore")
		return

	var user_id = UserData.current_auth.localid
	var col = Firebase.Firestore.collection("userInfo")
	var document = await col.get_doc(user_id)
	if not document:
		push_error("XPManager: User document not found; can't sync XP/level")
		return

	document.add_or_update_field("player_xp", xp)
	document.add_or_update_field("player_level", level)

	var ok = await col.update(document)
	#if ok:
		#print("XPManager: Firestore synced → xp=", xp, " level=", level)
	#else:
		#push_error("XPManager: Failed to sync XP/level to Firestore")

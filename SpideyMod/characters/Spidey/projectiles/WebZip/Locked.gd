extends ObjectState

const MAX_LOCK_TIME = 300

var was_attached = false

func _frame_0():
	was_attached = false
	pass

func _tick():
	host.update_rotation()
	var attached_to = host.obj_from_name(host.attached_to)
	#NOTE: Add an "and isn't max_distance
	if attached_to != null:
		if attached_to.disabled:
			host.unlock()

		else :
			was_attached = true
			var pos = attached_to.get_hurtbox_center()
			host.set_pos(pos.x, pos.y)
	else :
		if was_attached:
			host.unlock()
	if current_tick > MAX_LOCK_TIME:
		host.disable()

func _exit():
	was_attached = false

extends CharacterState

const SPEED = "25"
const MAX_DISTANCE = 160.0

export  var push_back_amount = "0"

var projectile_spawned = false

func _frame_0():
	projectile_spawned = false
	host.used_grappling_hook = true

func process_projectile(projectile):
#	host.play_sound("GrapplingHook")
	projectile_spawned = true
	projectile.set_grounded(false)
	var force = xy_to_dir(data.x, data.y, SPEED)
	var vel = host.get_vel()
	projectile.apply_force(fixed.add(vel.x, force.x), fixed.add(vel.y, force.y))
	host.grappling_hook_projectile = projectile.obj_name
	projectile.start_y = host.get_pos().y

func _tick():
	host.apply_fric()
	host.apply_forces()
	if air_type == AirType.Aerial and projectile_spawned:
		host.apply_grav()
		if host.is_grounded():
			return "Landing"
			

func is_usable():
	return host.grappling_hook_projectile == null and not host.used_grappling_hook and .is_usable()
	
#func _exit():
#	#Reduce Spidey's velocity upon exiting WebZip state
#	var vel = host.get_vel()
#	host.set_vel(fixed.div(vel.x,"4"), fixed.div(vel.y,"4"))

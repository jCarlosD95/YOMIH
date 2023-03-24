extends CharacterState

const SPEED = "25"
export var MAX_DISTANCE = 160.0

export  var push_back_amount = "0"

var projectile_spawned = false

func _frame_0():
	projectile_spawned = false
	host.used_grappling_hook = true

func process_projectile(projectile):
#	host.play_sound("GrapplingHook")
	projectile_spawned = true
	projectile.set_grounded(false)
	

	#This getx max x and max y, which have the same slope when plotted through (0,0) as data.x and data.y do when plotted through (0,0)
	var max_x = cos(radians(data.x,data.y))*100
	if data.x < 0:
		max_x = max_x *-1
	var max_y = sin(radians(data.x,data.y))*100
	if data.y < 0:
		max_y = max_y * -1
		
	var magnitude = vector_length(data.x, data.y)/100
	projectile.MAX_DISTANCE = MAX_DISTANCE * magnitude * 1.35

	
	#Use max_x and max_y instead of data.x and data.y to ensure that the web always travels at max velocity.
	var force = xy_to_dir(max_x, max_y, SPEED)
#	var vel = host.get_vel()
#	projectile.apply_force(fixed.add(vel.x, force.x), fixed.add(vel.y, force.y))
	projectile.apply_force(force.x, force.y)
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
	

#used in func radians
func vector_length(x,y):
	return pow(pow(x,2)+pow(y,2),0.5)
	
func radians(x,y):
	var ab = x
	var aabs = vector_length(x,y)
	var babs = vector_length(1,0)
	return acos(ab / aabs * babs)

#func _exit():
#	#Reduce Spidey's velocity upon exiting WebZip state
#	var vel = host.get_vel()
#	host.set_vel(fixed.div(vel.x,"4"), fixed.div(vel.y,"4"))

extends Fighter
#Used in WallCling.gd
var cling_x = 0
var cling_y = 0

#Used in WebZip.gd and other Web Zip-related scripts
var grappling_hook_projectile = null
var used_grappling_hook = false
var pulling = false

var lasso_projectile = null


const HOOK_DISABLE_DIST = "32"
const HOOK_PULL_SPEED = "30"
const MAX_PULL_SPEED = "30"
const MAX_PULL_UPWARD_SPEED = "0"

func process_extra(extra):
	.process_extra(extra)
	if extra.has("pull"):
		pulling = extra.pull
	if extra.has("detach"):
		if extra.detach:
			detach()


func detach():
	var hook = obj_from_name(grappling_hook_projectile)
	if hook:
		hook.disable()

func tick():
	.tick()

	#To activate wall cling, Spidey must be:
	#touching the wall
	#Not currently or previously in the middle of a WallCling
	#not currently hurt
	if touching_wall and not is_in_hurt_state() and current_state().state_name != "WallCling" and previous_state().state_name != "WallCling" :
		change_stance_to("WallCling")
		change_state("WallCling")
		
	
	var hook = obj_from_name(grappling_hook_projectile)
	if is_in_hurt_state():
		pulling = false
	if hook:
		if is_in_hurt_state(false):
			hook.disable()
		var hook_pos = obj_local_center(hook)
		#print_debug("The value of the weird thing: ", fixed.lt("300", HOOK_DISABLE_DIST))
		
		#Disables hook if Spidey gets too close to hooked target
		if hook.is_locked and hook.current_state().current_tick > 5 and fixed.lt(fixed.vec_len(str(hook_pos.x), str(hook_pos.y)), HOOK_DISABLE_DIST):
			hook.disable()
			
		if pulling:
			var dir = fixed.normalized_vec_times(str(hook_pos.x), str(hook_pos.y), HOOK_PULL_SPEED)
			apply_force(dir.x, dir.y)
			limit_speed(MAX_PULL_SPEED)
			var vel = get_vel()
			if fixed.lt(vel.y, MAX_PULL_UPWARD_SPEED):
				set_vel(vel.x, MAX_PULL_UPWARD_SPEED)
	else :
		pulling = false
	
	if is_grounded():
		used_grappling_hook = false
		
		
func _draw():
#	var hook = obj_from_name(grappling_hook_projectile)
#	if hook:
#		draw_line(to_local(get_center_position_float()), to_local(hook.get_center_position_float()), Color("#ffffff"), 2.0)
	lineDraw(grappling_hook_projectile)
	lineDraw(lasso_projectile)	

func lineDraw(object):
	var obj = obj_from_name(object)
	if obj:
		draw_line(to_local(get_center_position_float()), to_local(obj.get_center_position_float()), Color("#ffffff"), 2.0)

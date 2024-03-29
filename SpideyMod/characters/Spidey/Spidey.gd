extends Fighter
#Used in WallCling.gd
var cling_x = 0
var cling_y = 0

var swingkick_anchor_x = 0
var swingkick_anchor_y = 0

#Used in WebZip.gd and other Web Zip-related scripts
var grappling_hook_projectile = null
var used_grappling_hook = false
var pulling = false

var web_anchor = null
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
	._draw()
	
	#Gotta reincorporate Cowboy's linedraw because the one below it isn't working in itch.io version
#	if lasso_projectile:
#		var obj = objs_map[lasso_projectile]
#		var obj_pos = obj.get_pos()
#		var draw_target = to_local(Vector2(obj_pos.x, obj_pos.y))
#		draw_target -= draw_target.normalized() * 8
#		draw_line(Vector2(0, - 16), draw_target, Color("ffffff"), 2.0, false)
	
	
	
	
	
#	var hook = obj_from_name(grappling_hook_projectile)
#	if hook:
#		draw_line(to_local(get_center_position_float()), to_local(hook.get_center_position_float()), Color("#ffffff"), 2.0)
	
	#Get Spidey's Location
	var location = to_local(get_center_position_float())
	
	
	lineDraw(grappling_hook_projectile, location.x, location.y)
	lineDraw(lasso_projectile, location.x, location.y)	
	#Draw a line to Spidey's hand instead of to his center
	#Spidey's hand changes location depending on which way he's facing
	if get_facing() == "Right":
		lineDraw(web_anchor, -6, -38)
	else:
		lineDraw(web_anchor, 6, -38)

func lineDraw(object,x,y):
	#this "if" Doesn't work in itch.io because obj_from_name()isn't in BaseObj.gd in itch.io version
	#if obj_from_name(object):
	if object:	
		var obj = objs_map[object]
		#For some reason, you need this "if" because an object can exist after it's been disabled.
		if not obj.disabled:
			draw_line(Vector2(x,y), to_local(obj.get_center_position_float()), Color("#ffffff"), 2.0)


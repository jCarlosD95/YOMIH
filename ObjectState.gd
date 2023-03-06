extends StateInterface

class_name ObjectState

signal state_started()
signal state_ended()

export  var _c_Physics = 0
export  var apply_forces = false
export  var apply_fric = false
export  var apply_grav = false

export  var _c_Animation_and_Length = 0
export  var fallback_state = "Wait"
export  var sprite_animation = ""
export  var anim_length = 1
export  var sprite_anim_length = - 1
export  var ticks_per_frame = 1
export  var loop_animation = false
export  var absolute_loop = false
export  var endless = false

export  var _c_Static_Force = 0
export  var force_dir_x = "0.0"
export  var force_dir_y = "0.0"
export  var force_speed = "0.0"
export  var force_tick = 0

export  var _c_Enter_Static_Force = 0
export  var enter_force_dir_x = "0.0"
export  var enter_force_dir_y = "0.0"
export  var enter_force_speed = "0.0"
export  var reset_momentum = false

export  var _c_Particles = 0
export (PackedScene) var particle_scene = null
export  var particle_position = Vector2()
export  var spawn_particle_on_enter = false

export  var _c_Screenshake = 0
export  var state_screenshake_tick = - 1
export  var state_screenshake_dir = Vector2()
export  var state_screenshake_length = 0.25
export  var state_screenshake_amount = 10

export  var _c_TimedParticles = 0
export (PackedScene) var timed_particle_scene = null
export  var timed_particle_position = Vector2()
export  var timed_spawn_particle_tick = 1

export  var _c_Sfx = 0
export (AudioStream) var enter_sfx = null
export  var enter_sfx_volume = - 15.0
export (AudioStream) var sfx = null
export  var sfx_tick = 1
export  var sfx_volume = - 15.0

export  var _c_Projectiles = 0
export (PackedScene) var projectile_scene
export  var projectile_tick = 1
export  var projectile_pos_x = 0
export  var projectile_pos_y = 0
export  var projectile_local_pos = true

export  var _c_Flip = 0
export  var flip_frame = - 1

export  var _c_Meta = 0
export  var host_commands = {
}

export  var _c_Auto = 0
export  var throw_positions:Dictionary = {}

var enter_sfx_player
var sfx_player

var current_tick = - 1
var current_real_tick = - 1
var start_tick = - 1
var fixed

var anim_name

var has_hitboxes = false

var current_hurtbox = null

var hitbox_start_frames = {
}

var hurtbox_state_change_frames = {
	
}

var frame_methods = []
var frame_methods_shared = []
var max_tick = - 1
var max_tick_shared = - 1

func apply_enter_force():
	if enter_force_speed != "0.0":
		var force = xy_to_dir(enter_force_dir_x, enter_force_dir_y, enter_force_speed, "1.0")

		host.apply_force_relative(force.x, force.y)

func _on_hit_something(obj, hitbox):
	if hitbox.followup_state != "" and obj.is_in_group("Fighter"):
		queue_state_change(hitbox.followup_state)

func get_projectile_pos():
	return {"x":projectile_pos_x, "y":projectile_pos_y}

func get_projectile_data():
	return null

func process_projectile(_projectile):
	pass

func get_active_hitboxes():
	var hitboxes = []
	var pos = host.get_pos()
	for start_frame in hitbox_start_frames:
		var items = hitbox_start_frames[start_frame]
		for item in items:
			if item is Hitbox:
				item.update_position(pos.x, pos.y)
				hitboxes.append(item)
	return hitboxes

func _tick_before():
	pass

func process_feint():
	return fallback_state

func spawn_exported_projectile():
	if projectile_scene:
		var pos = get_projectile_pos()
		var obj = host.spawn_object(projectile_scene, pos.x, pos.y, true, get_projectile_data(), projectile_local_pos)
		process_projectile(obj)

func _tick_shared():




	if current_tick == - 1:
		if spawn_particle_on_enter and particle_scene:
			var pos = particle_position
			pos.x *= host.get_facing_int()
			spawn_particle_relative(particle_scene, pos, Vector2.RIGHT * host.get_facing_int())
		apply_enter_force()

	current_real_tick += 1
	if current_tick < anim_length or endless:
		current_tick += 1

		process_hitboxes()

		update_sprite_frame()
		update_hurtbox()
		if current_tick == sfx_tick and sfx_player and not ReplayManager.resimulating:
			sfx_player.play()
		if current_tick == force_tick:
			if force_speed != "0.0":
				var force = xy_to_dir(force_dir_x, force_dir_y, force_speed, "1.0")
		
				host.apply_force_relative(force.x, force.y)

		if current_tick == projectile_tick:
			spawn_exported_projectile()

		if current_tick == timed_spawn_particle_tick:
			if timed_particle_scene:
				var pos = timed_particle_position
				pos.x *= host.get_facing_int()
				spawn_particle_relative(timed_particle_scene, pos, Vector2.RIGHT * host.get_facing_int())

		if current_tick == state_screenshake_tick:
			host.screen_bump(state_screenshake_dir, state_screenshake_amount, state_screenshake_length)

		if current_tick == flip_frame:
			host.set_facing(host.get_facing_int() * - 1)

		if current_tick in host_commands:
			var command = host_commands[current_tick]
			if command is Array:
				if not command.empty():
					host.callv(command[0], command.slice(1, command.size() - 1))
			elif command is String:
				host.call(command)

		var new_max = false
		var new_max_shared = false
		if current_tick > max_tick:
			max_tick = current_tick
			new_max = true
			
		if current_tick > max_tick_shared:
			max_tick_shared = current_tick
			new_max_shared = true
		
		
		if host.is_ghost or new_max or current_tick in frame_methods_shared:
			var method_name = "_frame_" + str(current_tick) + "_shared"
			
			if has_method(method_name):
				if not (current_tick in frame_methods_shared):
					frame_methods_shared.append(current_tick)
				var next_state = call(method_name)
				if next_state != null:
					return next_state
			new_max = false
			
		if host.is_ghost or new_max_shared or current_tick in frame_methods:
			var method_name = "_frame_" + str(current_tick)
			
			if has_method(method_name):
				if not (current_tick in frame_methods):
					frame_methods.append(current_tick)
				var next_state = call(method_name)
				if next_state != null:
					return next_state
			new_max_shared = false


	if apply_fric:
		host.apply_fric()
	if apply_grav:
		host.apply_grav()
	if apply_forces:
		host.apply_forces()

func process_hitboxes():
	if hitbox_start_frames.has(current_tick + 1):
		for hitbox in hitbox_start_frames[current_tick + 1]:
			activate_hitbox(hitbox)
			if hitbox is Hitbox:
				if hitbox.hitbox_type == Hitbox.HitboxType.ThrowHit:
					hitbox.hit(host.opponent)
					hitbox.deactivate()
	for hitbox in get_active_hitboxes():
		hitbox.facing = host.get_facing()
		if hitbox.active:
			hitbox.tick()
		else :
			deactivate_hitbox(hitbox)


func update_hurtbox():
	if current_hurtbox:
		current_hurtbox.tick(host)
	if current_tick in hurtbox_state_change_frames:
		if current_hurtbox:
			current_hurtbox.end(host)
		current_hurtbox = hurtbox_state_change_frames[current_tick]
		current_hurtbox.start(host)
		
func copy_data():
	var d = null
	if data:
		if data is Dictionary or data is Array:
			d = data.duplicate()
		else :
			d = data
	return d

func copy_to(state:ObjectState):
	var properties = get_script().get_script_property_list()
	for variable in properties:
		var value = get(variable.name)
		if not (value is Object or value is Array or value is Dictionary):
			state.set(variable.name, value)
	state.data = copy_data()
	state.current_real_tick = current_real_tick
	state.current_tick = current_real_tick
	for h in get_children():
		if (h is Hitbox):
			h.copy_to(state.get_node(h.name))

func copy_hurtbox_states(state:ObjectState):
	for i in range(get_child_count()):
		var child = get_child(i)
		if child is HurtboxState:
			if child.started:
				state.get_child(i).start(state.host)
				state.current_hurtbox = state.get_child(i)
			child.copy_to(state.get_child(i))

func activate_hitbox(hitbox):
	hitbox.activate()

func terminate_hitboxes():
	for hitbox in get_active_hitboxes():
		hitbox.deactivate()

func deactivate_hitbox(hitbox):

	pass

func init():
	connect("state_started", host, "on_state_started", [self])
	connect("state_ended", host, "on_state_ended", [self])
	fixed = host.fixed
	anim_name = sprite_animation if sprite_animation else state_name
	if sprite_anim_length < 0:
		if host.sprite.frames.has_animation(anim_name):
			sprite_anim_length = host.sprite.frames.get_frame_count(anim_name)
		else :
			sprite_anim_length = anim_length
	setup_hitboxes()
	setup_hurtboxes()
	call_deferred("setup_audio")

func setup_audio():
	if enter_sfx:
		enter_sfx_player = VariableSound2D.new()
		add_child(enter_sfx_player)
		enter_sfx_player.bus = "Fx"
		enter_sfx_player.stream = enter_sfx
		enter_sfx_player.volume_db = enter_sfx_volume

	if sfx:
		sfx_player = VariableSound2D.new()
		add_child(sfx_player)
		sfx_player.bus = "Fx"
		sfx_player.stream = sfx
		sfx_player.volume_db = sfx_volume

func setup_hitboxes():
	var hitboxes = []
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			host.hitboxes.append(child)
	for hitbox in hitboxes:
		hitbox.init()
		has_hitboxes = true
		hitbox.host = host
		if hitbox.start_tick >= 0:
			if hitbox_start_frames.has(hitbox.start_tick):
				hitbox_start_frames[hitbox.start_tick].append(hitbox)
			else :
				hitbox_start_frames[hitbox.start_tick] = [hitbox]
		hitbox.connect("hit_something", self, "__on_hit_something")
		hitbox.connect("got_parried", self, "__on_got_parried")
		for hitbox2 in hitboxes:
			if hitbox2.group == hitbox.group:
				hitbox.grouped_hitboxes.append(hitbox2)

func setup_hurtboxes():
	for child in get_children():
		if child is HurtboxState:
			hurtbox_state_change_frames[child.start_tick] = child


func __on_hit_something(obj, hitbox):
	if active:
		_on_hit_something(obj, hitbox)

func __on_got_parried():
	if active:
		_got_parried()

func _got_parried():
	pass

func spawn_particle_relative(scene:PackedScene, pos = Vector2(), dir = Vector2.RIGHT):
	var p = host.get_pos_visual()
	return host.spawn_particle_effect(scene, p + pos, dir)

func _enter_shared():

	if reset_momentum:
		host.reset_momentum()
	current_tick = - 1
	current_real_tick = - 1
	start_tick = host.current_tick
	if enter_sfx_player and not ReplayManager.resimulating:
		enter_sfx_player.play()
	emit_signal("state_started")

func _exit_shared():
	if current_hurtbox:
		current_hurtbox.end(host)
	host.reset_hurtbox()

func xy_to_dir(x, y, mul = "1.0", div = "100.0"):
	return host.xy_to_dir(x, y, mul, div)

func update_sprite_frame():


	if not host.sprite.frames.has_animation(anim_name):
		return 
	if host.sprite.animation != anim_name:
		host.sprite.animation = anim_name
		host.sprite.frame = 0
	var sprite_tick = current_tick / ticks_per_frame

	if loop_animation and absolute_loop:
		sprite_tick = host.current_tick / ticks_per_frame
	var frame = (sprite_tick % sprite_anim_length) if loop_animation else Utils.int_min(sprite_tick, sprite_anim_length)
	host.sprite.frame = frame

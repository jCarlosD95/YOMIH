extends ObjectState

class_name CharacterState

signal state_interruptable()
signal state_hit_cancellable()

const WHIFF_SUPER_GAIN = 10

enum ActionType{
	Movement, 
	Attack, 
	Special, 
	Super, 
	Defense, 
	Hurt, 
}

enum BusyInterrupt{
	Normal, 
	Hurt, 
	None, 
}

enum AirType{
	Grounded, 
	Aerial, 
	Both
}

export  var _c_Menu = 0
export (String) var title
export  var show_in_menu = true
export (ActionType) var type
export (PackedScene) var data_ui_scene = null
export (Texture) var button_texture = null
export  var flip_icon = true
export  var flip_with_facing = false

export  var _c_Air_Data = 0
export (AirType) var air_type = AirType.Grounded
export  var uses_air_movement = false
export  var land_cancel = false

export  var _c_Interrupt_Data = 0
export  var iasa_at = - 1
export  var interrupt_frames = []
export  var throw_techable = false
export  var interruptible_on_opponent_turn = false
export  var update_facing_on_exit = true
export  var dynamic_iasa = true
export  var backdash_iasa = false
export  var allow_framecheat = false
export  var next_state_on_hold = true
export  var combo_only = false
export  var neutral_only = false

var starting_iasa_at = - 1
var starting_interrupt_frames = []

export  var _c_Interrupt_Categories = 0
export (BusyInterrupt) var busy_interrupt_type = BusyInterrupt.Normal
export  var burst_cancellable = true
export  var burstable = true
export  var self_hit_cancellable = true
export  var self_interruptable = true
export  var reversible = true
export  var instant_cancellable = true
export  var force_feintable = false
export  var can_feint_if_possible = true


export (String, MULTILINE) var interrupt_from_string
export (String, MULTILINE) var interrupt_into_string
export (String, MULTILINE) var hit_cancel_into_string
export (String, MULTILINE) var interrupt_exceptions_string
export (String, MULTILINE) var hit_cancel_exceptions_string

export  var _c_Stances = 0
export (String, MULTILINE) var allowed_stances_string = "Normal"
export (String) var change_stance_to = ""

export  var _c_Misc = 0
export  var release_opponent_on_startup = false
export  var release_opponent_on_exit = false
export  var initiative_effect = false
export  var initiative_startup_reduction_amount = 0
export  var apply_pushback = true
export  var beats_backdash = false
export  var no_collision_start_frame = - 1
export  var no_collision_end_frame = - 1
export  var can_be_counterhit = true
export  var tick_priority = 0

var initiative_effect_spawned = false

var dash_iasa = false
var started_in_air = false
var hit_yet = false
var hit_cancelled = false
var started_during_combo = false

var feinting = false

var interrupt_into = []
var interrupt_from = []
var interrupt_exceptions = []
var hit_cancel_into = []
var hit_cancel_exceptions = []
var busy_interrupt_into = []
var allowed_stances = []

var is_hurt_state = false
var start_interruptible_on_opponent_turn = false
var initiative_startup_reduction = false

func init():
	connect("state_interruptable", host, "on_state_interruptable", [self])
	connect("state_hit_cancellable", host, "on_state_hit_cancellable", [self])
	host.connect("got_hit", self, "on_got_hit")
	interrupt_into.append_array(get_categories(interrupt_into_string))
	interrupt_from.append_array(get_categories(interrupt_from_string))
	hit_cancel_into.append_array(get_categories(hit_cancel_into_string))
	hit_cancel_exceptions.append_array(get_categories(hit_cancel_exceptions_string))
	allowed_stances.append_array(get_categories(allowed_stances_string))
	interrupt_exceptions.append_array(get_categories(interrupt_exceptions_string))
	start_interruptible_on_opponent_turn = interruptible_on_opponent_turn
	if burst_cancellable:
		hit_cancel_into.append("OffensiveBurst")
	if instant_cancellable:
		hit_cancel_into.append("InstantCancel")
	if title == "":
		title = state_name
	match busy_interrupt_type:
		BusyInterrupt.Normal:
			busy_interrupt_into.append("BusyNormal")
		BusyInterrupt.Hurt:
			if burstable:
				busy_interrupt_into.append("BusyHurt")
		BusyInterrupt.None:
			pass
	if iasa_at < 0:
		iasa_at = anim_length + iasa_at
	if starting_iasa_at == - 1:
		starting_iasa_at = iasa_at
	interrupt_frames = interrupt_frames.duplicate(true)
	.init()





func get_ui_category():
	return ActionType.keys()[type]

func is_usable():
	if host.current_state().state_name == "WhiffInstantCancel" and not has_hitboxes:
		return false
	if air_type == AirType.Aerial:
		if host.is_grounded():
			return false
	if air_type == AirType.Grounded:
		if not host.is_grounded():
			return false
	if uses_air_movement:
		if host.air_movements_left <= 0:
			return false
	if type == ActionType.Defense and host.penalty_ticks > 0:
		return false
	if combo_only and host.combo_count < 1:
		return false
	if neutral_only and host.combo_count >= 1:
		return false
	return true

func get_categories(string:String):
	return Utils.split_lines(string)

func _enter_shared():
	._enter_shared()
	started_during_combo = false
	if dynamic_iasa:
		interruptible_on_opponent_turn = start_interruptible_on_opponent_turn



	hit_yet = false
	started_in_air = false
	host.update_grounded()
	if change_stance_to:
		host.change_stance_to(change_stance_to)
	if not host.is_grounded() or air_type == AirType.Aerial:
		started_in_air = true
	if uses_air_movement:
		if not host.infinite_resources and host.gravity_enabled:
			host.air_movements_left -= 1
	call_deferred("update_sprite_frame")
	if has_hitboxes:
		var dir = host.get_move_dir()
		if dir == 0 or dir == host.get_opponent_dir():
			host.add_penalty( - 8)
		host.gain_super_meter(WHIFF_SUPER_GAIN)

func allowed_in_stance():
	return "All" in allowed_stances or host.stance in allowed_stances

func enable_interrupt(check_opponent = true):
	if backdash_iasa:
		var opponent_state = host.opponent.current_state()
		if opponent_state.beats_backdash:
			return 
	if check_opponent and beats_backdash and host.opponent.current_state().beats_backdash:
		host.opponent.current_state().enable_interrupt(false)
		if not allow_framecheat:
			queue_state_change(fallback_state)
	if beats_backdash and host.opponent.current_state().backdash_iasa:
		if not host.opponent.current_state().allow_framecheat:
			host.opponent.current_state().queue_state_change(host.opponent.current_state().fallback_state)
		if not allow_framecheat:
			queue_state_change(fallback_state)

	emit_signal("state_interruptable")

func enable_hit_cancel():
	emit_signal("state_hit_cancellable")

func _on_hit_something(obj, hitbox):
	if not hit_yet and obj == host.opponent:
		hit_yet = true
		host.stack_move_in_combo(state_name)
	host.add_penalty( - 25)
	._on_hit_something(obj, hitbox)
	if hitbox.cancellable:
		if obj == host.opponent and obj.has_armor():
			return 


		if (( not burst_cancellable) or host.bursts_available == 0) and hit_cancel_into == ["OffensiveBurst"]:
			return 
		if hitbox is ThrowBox:
			return 
		if not can_hit_cancel():
			return 
		if obj.is_in_group("Fighter"):
			enable_hit_cancel()

func can_hit_cancel():
	return true

func process_hitboxes():




	.process_hitboxes()

func spawn_exported_projectile():
	.spawn_exported_projectile()

func _tick_shared():
	if current_tick == 0:
		initiative_startup_reduction = false
		feinting = host.feinting
		hit_cancelled = false

		var forward_movement_initiative = host.was_moving_forward()
		if (initiative_effect and host.initiative):
			if host.initiative_effect:
				host.spawn_particle_effect(preload("res://fx/YomiEffect.tscn"), host.get_center_position_float())
			host.initiative_effect = false
			if initiative_startup_reduction_amount > 0:
				initiative_startup_reduction = true



		host.moved_forward = false
		if release_opponent_on_startup:
			host.release_opponent()
		if not is_hurt_state and reversible:
			if host.reverse_state:
				var facing = host.get_facing_int()
				var opponent_x = host.opponent.get_pos().x
				var my_x = host.get_pos().x
				var equal_x = opponent_x == my_x
				host.set_facing(facing * ( - 1 if not equal_x else 1))
				host.update_data()
		else :
			host.reverse_state = false
		host.moved_backward = false
	if initiative_startup_reduction:
		current_tick += initiative_startup_reduction_amount
		initiative_startup_reduction = false




	if not host.is_grounded() or air_type == AirType.Aerial:
		started_in_air = true
	var next_state = ._tick_shared()
	if host.combo_count > 0 and hit_yet:
		started_during_combo = true

	if next_state:
		return next_state


	if land_cancel and host.is_grounded() and started_in_air and fixed.ge(host.get_vel().y, "0"):
		queue_state_change("Landing")
	if current_tick <= anim_length and not endless:
		if can_interrupt() and not interrupt_into.empty():
			enable_interrupt()
			if dynamic_iasa:
				interruptible_on_opponent_turn = true
	if current_tick == no_collision_start_frame:
		host.colliding_with_opponent = false
	if current_tick == no_collision_end_frame:
		host.colliding_with_opponent = true

func _tick_after():























	host.set_lowest_tick(current_real_tick)
	._tick_after()

func update_parameters():
	pass

func can_feint():
	return (has_hitboxes or force_feintable) and host.feints > 0 and can_feint_if_possible

func can_interrupt():
	return current_tick == iasa_at or current_tick in interrupt_frames or current_tick == anim_length - 1

func on_got_hit():
	pass

func _exit_shared():
	beats_backdash = false
	if feinting:
		host.update_facing()
		host.feinting = false
	feinting = false


	._exit_shared()
	if update_facing_on_exit:
		host.update_facing()
	else :
		host.set_facing(host.get_facing_int())
	terminate_hitboxes()
	host.end_invulnerability()
	host.end_projectile_invulnerability()
	host.end_throw_invulnerability()
	if release_opponent_on_exit:
		host.release_opponent()
	host.got_parried = false
	host.colliding_with_opponent = true
	host.state_interruptable = false
	host.has_hyper_armor = false
	host.state_hit_cancellable = false
	host.clipping_wall = false



	emit_signal("state_ended")
	host.z_index = 0

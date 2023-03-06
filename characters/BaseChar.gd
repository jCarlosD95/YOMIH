extends BaseObj

class_name Fighter

signal action_selected(action, data)
signal super_started()
signal parried()
signal got_parried()
signal undo()
signal forfeit()
signal clashed()
signal predicted()



var MAX_HEALTH = 1000













const MAX_STALES = 15
const MIN_STALE_MODIFIER = "0.2"

const COMBO_DI_SCALING_DIVISOR = "3"
const WALL_SLAM_DAMAGE = "0.75"

const DAMAGE_SUPER_GAIN_DIVISOR = 1
const DAMAGE_TAKEN_SUPER_GAIN_DIVISOR = 3
const HITLAG_COLLISION_TICKS = 4
const PROJECTILE_PERFECT_PARRY_WINDOW = 3
const BURST_ON_DAMAGE_AMOUNT = 5

const MAX_WALL_SLAMS = 3

const COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES = 3

const MAX_GROUNDED_HITS = 7
const PREDICTION_CORRECT_SUPER_GAIN = 30
const INCORRECT_PREDICTION_LAG = 7

const PARRY_CHIP_DIVISOR = 3
const PARRY_KNOCKBACK_DIVISOR = "3"

const DISTANCE_EXTRA_SADNESS = "180"
const MIN_DIST_SADNESS = "128"

const HOLD_RESTARTS = [
	"Wait", 
	"Fall", 
	"DashForward", 

	"ParryHigh", 
	"ParryLow", 
	"ParryAir", 
]

var HOLD_FORCE_STATES = {



	"DashBackward":"Wait", 

}

const P1_COLOR = Color("aca2ff")
const P2_COLOR = Color("ff7a81")

const GUTS_REDUCTIONS = {
	"1":"1", 


	"0.70":"0.90", 
	"0.60":"0.80", 
	"0.50":"0.70", 
	"0.40":"0.60", 
	"0.30":"0.55", 
	"0.20":"0.52", 
	"0.10":"0.50", 
}

const MAX_GUTS = 10

const MAX_DI_COMBO_ENHANCMENT = 15

const MAX_BURSTS = 1
const BURST_BUILD_SPEED = 4
const MAX_BURST_METER = 1500
const START_BURSTS = 1

const MAX_SUPER_METER = 125
const MAX_SUPERS = 9
const VEL_SUPER_GAIN_DIVISOR = 4


const NUDGE_DISTANCE = 20

const PARRY_METER = 50
const METER_GAIN_MODIFIER = "1.0"

const CLASH_MOVE_BACK = 3

const MIN_PENALTY = - 50
const MAX_PENALTY = 75
const PENALTY_MIN_DISPLAY = 50

const PENALTY_TICKS = 120

export  var num_air_movements = 2

export (Texture) var character_portrait

onready var you_label = $YouLabel
onready var actionable_label = $ActionableLabel
onready var quitter_label = $"%QuitterLabel"

var input_state = InputState.new()

var color = Color.white

export (PackedScene) var player_info_scene
export (PackedScene) var player_extra_params_scene

export  var damage_taken_modifier = "1.0"
var global_damage_modifier = "1.0"
var global_hitstun_modifier = "1.0"
var global_hitstop_modifier = "1.0"

export  var num_feints = 2


var opponent

var actions = 0

var queued_action = null
var queued_data = null
var queued_extra = null

var dummy_interruptable = false

var game_over = false
var forfeit = false
var will_forfeit = false

var applied_style = null
var is_color_active = false
var is_aura_active = false
var is_style_active = null
var touching_wall = false
var was_my_turn = false

var touch_of_death = true

var ivy_effect = false
var ivy_effect_t = 0.0

var colliding_with_opponent = true

var air_movements_left = 0

var action_cancels = {
}

var ghost_ready_tick = null
var ghost_ready_set = false
var got_parried = false

var di_enabled = true
var turbo_mode = false
var extremely_turbo_mode = false
var infinite_resources = false
var one_hit_ko = false
var burst_enabled = true
var always_perfect_parry = false
var blocked_last_hit = false
var sadness_enabled = false

var trail_hp:int = MAX_HEALTH
var hp:int = 0
var super_meter:int = 0
var supers_available:int = 0
var combo_proration:int = 0

var parried_last_state = false
var initiative_effect = false

var clipping_wall = false
var burst_meter:int = 0
var bursts_available:int = 0

var busy_interrupt = false
var any_available_actions = true
var refresh_prediction = false

var moved_forward = false
var buffer_moved_forward = false

var moved_backward = false
var buffer_moved_backward = false

var had_sadness = false

var state_changed = false
var on_the_ground = false
var nudge_amount = "1.0"
var used_air_dodge = false

var has_hyper_armor = false
var hit_during_armor = false

var wall_slams = 0

var last_pos = null
var penalty = 0
var penalty_buffer = 0
var penalty_ticks = 0


var emote_tween:SceneTreeTween

var feints = 2



var current_nudge = {
	"x":"0", 
	"y":"0", 
}

var current_di = {
	"x":"0", 
	"y":"0", 
}

var last_vel = {
	"x":"0", 
	"y":"0", 
}

var last_aerial_vel = {
	"x":"0", 
	"y":"0", 
}

var combo_moves_used = {}

var reverse_state = false
var ghost_reverse = false

var nudge_distance_left = 0

var can_nudge = false
var parried = false

var initiative = false
var aura_particle = null

var feinting = false
var clashing = false




var last_action = 0

var stance = "Normal"

var parried_hitboxes = []

var grounded_hits_taken = 0

var throw_pos_x = 16
var throw_pos_y = - 5

var combo_supers = 0
var combo_damage = 0
var hitlag_applied = 0
var forfeit_ticks = 0

var hitstun_decay_combo_count = 0

var lowest_tick = 0

class InputState:
	var name
	var data

func clash():
	clashing = true
	update_grounded()
	on_state_interruptable(current_state())

	var vel = get_vel()
	set_vel("0", vel.y)
	

	add_pushback(str( - CLASH_MOVE_BACK))
	emit_signal("clashed")

func init(pos = null):
	.init(pos)
	if not is_ghost:
		Network.player_objects[id] = self
	feints = num_feints
	if one_hit_ko:
		MAX_HEALTH = 1
	hp = MAX_HEALTH
	game_over = false
	show_you_label()
	if burst_enabled:
		for i in range(START_BURSTS):
			gain_burst()
	for state in state_machine.get_children():
		if state is CharacterState:
			for category in state.interrupt_from:
				if not action_cancels.has(category):
					action_cancels[category] = []
				if not (state in action_cancels[category]):
					action_cancels[category].append(state)
	if infinite_resources:
		supers_available = MAX_SUPERS
		super_meter = MAX_SUPER_METER
	last_pos = get_pos()


func is_ivy():
	if not Network.multiplayer_active and not SteamLobby.SPECTATING:
		var username = Network.pid_to_username(id)
		if username == "ivy sly":
			return true
	else :
		if id in Network.network_ids:
			return Network.network_ids[id] == SteamHustle.IVY_ID
	return false




func apply_style(style):
	if ( not SteamHustle.STARTED) or Global.steam_demo_version:
		return 
	
	if style != null and not is_ghost:
		ivy_effect = is_ivy() and style.style_name == "ivy"
		is_color_active = true
		is_style_active = true
		applied_style = style
		if Global.enable_custom_colors and style.has("character_color") and style.character_color != null:
			set_color(style.character_color)
			Custom.apply_style_to_material(style, sprite.get_material())
		if Global.enable_custom_particles and not is_ghost and style.show_aura and style.has("aura_settings"):
			reset_aura()
			is_aura_active = true
			aura_particle = preload("res://fx/CustomTrailParticle.tscn").instance()
			particles.add_child(aura_particle)
			aura_particle.load_settings(style.aura_settings)
			aura_particle.position = hurtbox_pos_float()
			aura_particle.start_emitting()
			if aura_particle.show_behind_parent:
				aura_particle.z_index = - 1
		if style.has("hitspark"):
			custom_hitspark = load(Custom.hitsparks[style.hitspark])
			for hitbox in hitboxes:
				hitbox.HIT_PARTICLE = custom_hitspark


func reset_color():
	is_color_active = false
	sprite.get_material().set_shader_param("color", P1_COLOR if id == 1 else P2_COLOR)
	sprite.get_material().set_shader_param("use_outline", false)

func reset_aura():
	is_aura_active = false
	if is_instance_valid(aura_particle):
		aura_particle.queue_free()
	aura_particle = null

func reset_style():
	reset_color()
	reset_aura()
	is_style_active = false

func reapply_style():
	apply_style(applied_style)

func start_super():
	emit_signal("super_started")

func change_stance_to(stance):
	self.stance = stance

func show_you_label():
	if is_you(false):
		you_label.show()

func is_you(default = true):
	if Network.multiplayer_active:
		return id == Network.player_id
	return default

func unlock_achievement(achievement_name, multiplayer_only = false):
	if not can_unlock_achievements():
		return 
	if is_you( not multiplayer_only):
		SteamHustle.unlock_achievement(achievement_name)

func can_unlock_achievements():
	if ReplayManager.playback or ReplayManager.replaying_ingame:
		return false
	if is_ghost:
		return false
	if SteamLobby.SPECTATING:
		return false
	return is_you()

func _ready():
	sprite.animation = "Wait"
	state_variables.append_array(
		["current_di", "current_nudge", "penalty_buffer", "was_my_turn", "combo_supers", "penalty_ticks", "can_nudge", "buffer_moved_backward", "wall_slams", "moved_backward", "moved_forward", "buffer_moved_forward", "used_air_dodge", "refresh_prediction", "clipping_wall", "has_hyper_armor", "hit_during_armor", "colliding_with_opponent", "clashing", "last_pos", "penalty", "hitstun_decay_combo_count", "touching_wall", "feinting", "feints", "lowest_tick", "is_color_active", "blocked_last_hit", "combo_proration", "state_changed", "nudge_amount", "initiative_effect", "reverse_state", "combo_moves_used", "parried_last_state", "initiative", "last_vel", "last_aerial_vel", "trail_hp", "always_perfect_parry", "parried", "got_parried", "parried_this_frame", "grounded_hits_taken", "on_the_ground", "hitlag_applied", "combo_damage", "burst_enabled", "di_enabled", "turbo_mode", "infinite_resources", "one_hit_ko", "dummy_interruptable", "air_movements_left", "super_meter", "supers_available", "parried", "parried_hitboxes", "burst_meter", "bursts_available"]
	)
	add_to_group("Fighter")
	connect("got_hit", self, "on_got_hit")
	connect("got_hit_by_fighter", self, "on_got_hit_by_fighter")
	connect("got_hit_by_projectile", self, "on_got_hit_by_projectile")
	state_machine.connect("state_changed", self, "on_state_changed")

func on_state_changed(states_stack):
	if buffer_moved_forward:
		buffer_moved_forward = false
		moved_forward = true
	if buffer_moved_backward:
		buffer_moved_backward = false
		moved_backward = true
	pass

func on_got_hit():
	pass

func on_got_hit_by_fighter():
	pass

func on_got_hit_by_projectile():
	pass

func gain_burst_meter(amount = null):
	if not burst_enabled:
		return 
	if bursts_available < MAX_BURSTS:
		burst_meter += BURST_BUILD_SPEED if amount == null else amount
		if burst_meter > MAX_BURST_METER:
			gain_burst()

func copy_to(f):
	.copy_to(f)
	f.got_parried = got_parried
	f.colliding_with_opponent = colliding_with_opponent
	f.has_hyper_armor = has_hyper_armor
	f.current_state().interrupt_frames = current_state().interrupt_frames.duplicate(true)
	f.update_data()
	f.set_facing(get_facing_int(), true)

	f.update_data()
	

func gain_burst():
	if bursts_available < MAX_BURSTS:
		bursts_available += 1
		burst_meter = 0

func use_burst():


	bursts_available -= 1
	refresh_air_movements()

func use_burst_meter(amount):


	if bursts_available > 0:
		bursts_available = 0
		burst_meter = MAX_BURST_METER
	burst_meter -= amount

func use_super_bar():
	if infinite_resources:
		return 
	supers_available -= 1
	if supers_available < 0:
		supers_available = 0
		super_meter = 0

func use_super_meter(amount):
	if infinite_resources:
		return 
	super_meter -= amount
	if super_meter < 0:
		if supers_available > 0:
			super_meter = MAX_SUPER_METER + super_meter
			use_super_bar()
		else :
			super_meter = 0

func stack_move_in_combo(move_name):
	if combo_moves_used.has(move_name):
		combo_moves_used[move_name] += 1
	else :
		combo_moves_used[move_name] = 1

func meter_gain_modified(amount):

	if penalty_ticks > 0:
		return 0
	var pen = fixed.div(str(penalty), str(MAX_PENALTY))
	if penalty <= 0:
		pen = fixed.div(pen, "5.0")
	amount = fixed.round(fixed.mul(fixed.sub("1", pen), str(amount)))
	return amount

func gain_super_meter(amount):
	if amount == null:
		return 
	amount = combo_stale_meter(amount)
	amount = meter_gain_modified(amount)
	amount = fixed.round(fixed.div(str(amount), fixed.powu("2", combo_supers)))
	super_meter += amount
	if super_meter >= MAX_SUPER_METER:
		if supers_available < MAX_SUPERS:
			super_meter -= MAX_SUPER_METER
			supers_available += 1
		else :
			super_meter = MAX_SUPER_METER
			if not infinite_resources:
				unlock_achievement("ACH_ULTIMATE_POWER", true)


func spawn_object(projectile:PackedScene, pos_x:int, pos_y:int, relative = true, data = null, local = true):
	var obj = .spawn_object(projectile, pos_x, pos_y, relative, data, local)
	if obj is BaseProjectile:
		add_penalty( - 2)
	return obj

func combo_stale_meter(meter:int):
	var staling = get_combo_stale(combo_count)
	return fixed.round(fixed.mul(fixed.mul(str(meter), staling), METER_GAIN_MODIFIER))
	
func update_data():
	data = get_data()
	obj_data = data["object_data"]
	data["state_data"] = {
		"state":current_state().state_name, 
		"frame":current_state().current_tick, 
		"combo count":combo_count, 
	}

func emote(message):
	ReplayManager.emote(message, id, current_tick)
	if not Global.enable_emotes:
		return 
	if is_instance_valid(emote_tween):
		emote_tween.kill()
	emote_tween = create_tween()
	$EmoteLabel.text = ProfanityFilter.filter(message)
	$EmoteLabel.show()
	emote_tween.tween_method(self, "set_emote_visible", 1.0, 0.0, 3.0)

func set_emote_visible(amount:float):
	if amount <= 0.001:
		$EmoteLabel.visible = false
		return 
	$EmoteLabel.visible = true

func get_playback_input():
	if ReplayManager.playback:
		if get_frames().has(current_tick):
			return get_frames()[current_tick]

func get_global_throw_pos():
	var pos = get_pos()
	pos.x += throw_pos_x * get_facing_int()
	pos.y += throw_pos_y
	return pos

func emit_hit_by_signal(hitbox):
	emit_signal("got_hit")
	if hitbox == null:
		return 
	if hitbox.get("host") == null:
		return 
	if hitbox.host is String:
		var host = objs_map[hitbox.host]
		if host.is_in_group("Fighter"):
			emit_signal("got_hit_by_fighter")
		else :
			emit_signal("got_hit_by_projectile")

func reset_combo():
	if combo_damage >= 500:
		unlock_achievement("ACH_5000_DAMAGE")
	if touch_of_death and combo_damage >= 1000:
		if not one_hit_ko and not turbo_mode and not extremely_turbo_mode and not infinite_resources and fixed.eq(global_damage_modifier, "1") and fixed.eq(global_hitstop_modifier, "1") and fixed.eq(global_hitstun_modifier, "1"):
			unlock_achievement("ACH_TOUCH_OF_DEATH")
	if combo_count >= 20:
		unlock_achievement("ACH_RELENTLESS", true)
	if combo_count > 0 and not is_ghost:
		touch_of_death = false
	combo_count = 0
	combo_damage = 0
	hitstun_decay_combo_count = 0
	combo_proration = 0
	combo_moves_used = {}
	combo_supers = 0
	opponent.grounded_hits_taken = 0
	opponent.trail_hp = opponent.hp
	opponent.wall_slams = 0

func incr_combo():
	combo_count += 1
	hitstun_decay_combo_count += 1
	if combo_count == 2 and combo_moves_used.has("Burst"):
		unlock_achievement("ACH_UNFAIR")

func is_colliding_with_opponent():
	return ((colliding_with_opponent or (current_state() is CharacterHurtState and (hitlag_applied - hitlag_ticks) < HITLAG_COLLISION_TICKS)) and current_state().state_name != "Grabbed")

func thrown_by(hitbox:ThrowBox):
	emit_signal("got_hit")
	state_machine._change_state("Grabbed")

func hitbox_from_name(hitbox_name):
	var hitbox_props = hitbox_name.split("_")
	var obj_name = hitbox_props[0]
	var hitbox_id = int(hitbox_props[ - 1])
	var obj = objs_map[obj_name]
	if obj:
		return objs_map[obj_name].hitboxes[hitbox_id]

func _process(delta):
	if ivy_effect and not is_ghost:
		sprite.get_material().set_shader_param("color", Color.from_hsv(ivy_effect_t, 0.8, 1))

		ivy_effect_t += delta
		ivy_effect_t = fmod(ivy_effect_t, 1.0)


	if invulnerable:
		if (Global.current_game.real_tick / 1) % 2 == 0:
			var transparent = color
			self_modulate.a = 0.5

		else :
			self_modulate.a = 1.0

	else :
		self_modulate.a = 1.0
	if is_instance_valid(aura_particle):
		aura_particle.visible = Global.enable_custom_particles
		aura_particle.position = hurtbox_pos_float()
		aura_particle.facing = get_facing_int()
	
	if is_style_active:
		if applied_style and not is_color_active and Global.enable_custom_colors:
			apply_style(applied_style)
		if applied_style and not is_aura_active and Global.enable_custom_particles:
			apply_style(applied_style)
	if is_color_active and not Global.enable_custom_colors:
		reset_color()
	if is_aura_active and not Global.enable_custom_particles:
		reset_aura()







func debug_text():
	.debug_text()
	debug_info(
		{
			"lowest_tick":lowest_tick, 
			"initiative":initiative, 
			"penalty":penalty, 
		}
	)

func has_armor():
	return has_hyper_armor

func launched_by(hitbox):


	hitlag_ticks = hitbox.victim_hitlag + (COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES if hitbox.counter_hit else 0)
	hitlag_ticks = fixed.round(fixed.mul(str(hitlag_ticks), global_hitstop_modifier))
	hitlag_applied = hitlag_ticks
	
	if objs_map.has(hitbox.host):
		var host = objs_map[hitbox.host]
		var host_hitlag_ticks = fixed.round(fixed.mul(str(hitbox.hitlag_ticks), global_hitstop_modifier))
		if host.hitlag_ticks < host_hitlag_ticks:
			host.hitlag_ticks = host_hitlag_ticks
	
	
	
	if hitbox.rumble:
		rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
	
	nudge_amount = hitbox.sdi_modifier
	
	var will_launch = hitbox.ignore_armor or not has_armor()
	

	if will_launch:
		var state
		if is_grounded():
			state = hitbox.grounded_hit_state
		else :
			state = hitbox.aerial_hit_state

		if state == "HurtGrounded":
			grounded_hits_taken += 1
			if grounded_hits_taken >= MAX_GROUNDED_HITS:
				if not hitbox.force_grounded:
					state = "HurtAerial"
					grounded_hits_taken = 0

		state_machine._change_state(state, {"hitbox":hitbox})
		if hitbox.disable_collision:
			colliding_with_opponent = false

		busy_interrupt = true
		can_nudge = true
				
		if opponent.combo_count == 0:
			opponent.combo_proration = hitbox.damage_proration

		var host = objs_map[hitbox.host]
		var projectile = not host.is_in_group("Fighter")

		if not projectile:
			refresh_feints()
			opponent.refresh_feints()



		if hitbox.increment_combo:
			opponent.incr_combo()
	if has_hyper_armor:
		hit_during_armor = true

	emit_hit_by_signal(hitbox)
	take_damage(hitbox.get_damage(), hitbox.minimum_damage, hitbox.meter_gain_modifier)

	if will_launch:
		state_tick()

func hit_by(hitbox):
	if parried:
		return 
	if hitbox.name in parried_hitboxes:
		return 
	if not hitbox.hits_otg and is_otg():
		return 
	if not hitbox.hits_vs_dizzy and current_state().state_name == "HurtDizzy":
		return 
	if hitbox.throw and not is_otg():
		return thrown_by(hitbox)
	if not can_parry_hitbox(hitbox):
		
		match hitbox.hitbox_type:
			Hitbox.HitboxType.Normal:
				launched_by(hitbox)
			Hitbox.HitboxType.Burst:
				launched_by(hitbox)
			Hitbox.HitboxType.Flip:
				set_facing(get_facing_int() * - 1, true)
				var vel = get_vel()
				set_vel(fixed.mul(vel.x, "-1"), vel.y)
				for hitbox in hitboxes:
					hitbox.facing = get_facing()
					pass
				emit_signal("got_hit")
				take_damage(hitbox.get_damage(), hitbox.minimum_damage, hitbox.meter_gain_modifier)
			Hitbox.HitboxType.ThrowHit:
				emit_signal("got_hit")
				take_damage(hitbox.get_damage(), hitbox.minimum_damage, hitbox.meter_gain_modifier)
				opponent.incr_combo()
			Hitbox.HitboxType.OffensiveBurst:
				opponent.hitstun_decay_combo_count = 0
				opponent.combo_proration = Utils.int_min(opponent.combo_proration, 0)
				launched_by(hitbox)
				reset_pushback()
				opponent.reset_pushback()
	else :
		opponent.got_parried = true
		
		var host = objs_map[hitbox.host]
		var projectile = not host.is_in_group("Fighter")
		var perfect_parry
		if not projectile:
			perfect_parry = current_state().can_parry and (always_perfect_parry or opponent.current_state().feinting or opponent.feinting or (initiative and not blocked_last_hit) or parried_last_state)
			opponent.feinting = false
			opponent.current_state().feinting = false
		else :

			perfect_parry = current_state().can_parry and (always_perfect_parry or host.always_parriable or parried_last_state or (current_state().current_tick < PROJECTILE_PERFECT_PARRY_WINDOW and host.has_projectile_parry_window))
		if perfect_parry:
			parried_last_state = true
		else :
			blocked_last_hit = true

		parried = true

		hitlag_ticks = 0
		parried_hitboxes.append(hitbox.name)
		var particle_location = current_state().get("particle_location")
		particle_location.x *= get_facing_int()
		
		if not particle_location:
			particle_location = hitbox.get_overlap_center_float(hurtbox)
		var parry_meter = PARRY_METER if hitbox.parry_meter_gain == - 1 else hitbox.parry_meter_gain
		
		current_state().parry(perfect_parry)
		if not perfect_parry:
			if not projectile:
				opponent.add_penalty( - 25)
			take_damage(hitbox.damage / PARRY_CHIP_DIVISOR)
			apply_force_relative(fixed.div(hitbox.knockback, fixed.mul(PARRY_KNOCKBACK_DIVISOR, "-1")), "0")
			gain_super_meter(parry_meter / 3)
			opponent.gain_super_meter(parry_meter / 3)
			if not projectile:
				current_state().anim_length = opponent.current_state().anim_length
				current_state().endless = opponent.current_state().endless
				current_state().iasa_at = opponent.current_state().iasa_at



			spawn_particle_effect(preload("res://fx/FlawedParryEffect.tscn"), get_pos_visual() + particle_location)
			parried = false
			play_sound("Block")
			play_sound("Parry")
		else :
			if not projectile:
				opponent.add_penalty( - 25)
				add_penalty( - 25)
			else :
				if host.has_method("on_got_parried"):
					host.on_got_parried()
			gain_super_meter(parry_meter)
			spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), get_pos_visual() + particle_location)
			play_sound("Parry2")
			play_sound("Parry")
			emit_signal("parried")

func parry_effect(location, absolute = false):
	if not absolute:
		spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), get_pos_visual() + location)
	else :
		spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), location)
	play_sound("Parry2")
	play_sound("Parry")

func set_throw_position(x:int, y:int):
	throw_pos_x = x
	throw_pos_y = y

func get_penalty_damage_modifier():
	var min_penalty_for_damage = 20
	if penalty_ticks > 0:
		return "1.5"
	if penalty < min_penalty_for_damage:
		return "1.0"
	return fixed.add("1.0", fixed.mul(fixed.div(str(penalty - min_penalty_for_damage), str(MAX_PENALTY - min_penalty_for_damage)), "0.5"))

func take_damage(damage:int, minimum = 0, meter_gain_modifier = "1.0"):
	if opponent.combo_count == 0:
		trail_hp = hp
	if damage == 0:
		return 
	gain_burst_meter(damage / BURST_ON_DAMAGE_AMOUNT)
	var damage_score = Utils.int_max(damage, minimum)
	damage = Utils.int_max(combo_stale_damage(damage), 1)
	damage = Utils.int_max(damage, minimum)
	damage = Utils.int_max(guts_stale_damage(damage), 1)
	damage = fixed.round(fixed.mul(str(damage), get_penalty_damage_modifier()))
	opponent.gain_super_meter(damage / DAMAGE_SUPER_GAIN_DIVISOR)
	gain_super_meter(damage / DAMAGE_TAKEN_SUPER_GAIN_DIVISOR)
	damage = fixed.round(fixed.mul(fixed.mul(str(damage), damage_taken_modifier), global_damage_modifier))
	opponent.combo_damage += damage
	hp -= damage
	add_penalty( - 25)
	if hp < 0:
		hp = 0

func get_guts():
	var current_guts = "1"
	for level in GUTS_REDUCTIONS:
		var hp_level = fixed.div(str(hp), str(MAX_HEALTH))
		if fixed.le(hp_level, level):
			current_guts = GUTS_REDUCTIONS[level]
	return current_guts

func get_combo_stale(count):
	var ratio = fixed.div(fixed.sub(str(MAX_STALES), str(Utils.int_min(count, MAX_STALES))), str(MAX_STALES))
	var mod = fixed.mul(fixed.sub("1", MIN_STALE_MODIFIER), fixed.powu(ratio, 2))
	mod = fixed.add(mod, MIN_STALE_MODIFIER)
	return mod

func guts_stale_damage(damage:int):
	var guts = get_guts()
	damage = fixed.round(fixed.mul(str(damage), guts))
	return damage

func combo_stale_damage(damage:int):
	var staling = get_combo_stale(Utils.int_max(opponent.combo_count + (opponent.combo_proration if opponent.combo_count > 1 else 0) - 1, 0))
	return fixed.round(fixed.mul(str(damage), staling))

func can_parry_hitbox(hitbox):
	if not current_state() is ParryState:
		return false
	if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
		return false
	return current_state().can_parry_hitbox(hitbox)

func set_color(color:Color):
	if color != null:
		sprite.get_material().set_shader_param("color", color)
		self.color = color

func release_opponent():
	if opponent.current_state().state_name == "Grabbed":
		opponent.change_state("Fall")

func get_di_scaling():
	return fixed.add("1.0", fixed.mul("1.0", fixed.div(str(Utils.int_min(MAX_DI_COMBO_ENHANCMENT, opponent.combo_count)), COMBO_DI_SCALING_DIVISOR)))

func get_scaled_di(di):
	return xy_to_dir(di.x, di.y, get_di_scaling())

func process_extra(extra):
	if "DI" in extra:
		if di_enabled:
			var di = extra["DI"]
			current_nudge = xy_to_dir(di.x, di.y, str(NUDGE_DISTANCE))
			current_di = di
		else :
			current_di = {
				"x":0, 
				"y":0, 
			}
	if "reverse" in extra:
		reverse_state = extra["reverse"]
		if reverse_state:
			ghost_reverse = true
	if "feint" in extra:
		feinting = extra.feint
		if feinting and not infinite_resources:
			feints -= 1



	else :
		feinting = false

func refresh_air_movements():
	air_movements_left = num_air_movements

func refresh_feints():
	feints = num_feints
















func clean_parried_hitboxes():


	if not parried_hitboxes:
		return 
	var hitboxes_to_refresh = []
	for hitbox_name in parried_hitboxes:
		var hitbox = hitbox_from_name(hitbox_name)
		if hitbox:
			if not hitbox.enabled or not hitbox.active:
				hitboxes_to_refresh.append(hitbox)

	for hitbox in hitboxes_to_refresh:
		parried_hitboxes.erase(hitbox.name)

func get_opponent_dir():
	return Utils.int_sign(opponent.get_pos().x - get_pos().x)

func get_opponent():
	return opponent

func get_advantage():
	if opponent == null:
		return true
	if combo_count > 0:
		return true

	var minus_modifier = 0
	var advantage = (opponent and opponent.lowest_tick <= lowest_tick) or parried_last_state


	if state_interruptable and opponent.state_interruptable:
		advantage = true


	if was_moving_backward():
		advantage = false

	if current_state().state_name == "WhiffInstantCancel" or (previous_state() and previous_state().state_name == "WhiffInstantCancel" and current_state().has_hitboxes):
		advantage = false
	if opponent.current_state().state_name == "WhiffInstantCancel" or (opponent.previous_state() and opponent.previous_state().state_name == "WhiffInstantCancel" and opponent.current_state().has_hitboxes):
		advantage = false
	return advantage

func was_moving_forward():
	return moved_forward and current_state().has_hitboxes

func was_moving_backward():
	return moved_backward


func set_lowest_tick(tick):
	if lowest_tick == null or tick < lowest_tick:
		lowest_tick = tick

func update_advantage():
	var new_adv = get_advantage()
	if new_adv and not initiative:
		initiative_effect = true
	initiative = new_adv

func tick_before():
	if queued_action == "Forfeit":
		if forfeit:
			queued_action = "Continue"
	if clashing:
		if is_grounded():
			change_state("Wait")
		else :
			change_state("Fall")
		clashing = false
	dummy_interruptable = false
	clean_parried_hitboxes()
	busy_interrupt = false
	update_grounded()
	if ReplayManager.playback:
		var input = get_playback_input()
		if input:
			queued_action = input["action"]
			queued_data = input["data"]
			queued_extra = input["extra"]

			if queued_action == "Forfeit":

				forfeit = true
				Global.current_game.forfeit(id)
	else :
		if queued_action:
			actions += 1

			if queued_action == "Undo":
				queued_action = null
				queued_data = null
				return 

			if queued_action == "Forfeit":
				forfeit = true

			if not is_ghost:
				ReplayManager.frames[id][current_tick] = {
					"action":queued_action, 
					"data":queued_data, 
					"extra":queued_extra, 
				}
	var feinted_last = feinting
	var pressed_feint = false
	if refresh_prediction:
		refresh_prediction = false



	if queued_extra:
		process_extra(queued_extra)
		pressed_feint = feinting
	if queued_action:
		if queued_action == "Continue":
			var current_state_name = current_state().name
			if current_state_name in HOLD_RESTARTS and current_state().interruptible_on_opponent_turn:
				queued_action = current_state_name
				queued_data = current_state().data
			elif current_state_name in HOLD_FORCE_STATES and current_state().interruptible_on_opponent_turn:
				queued_action = HOLD_FORCE_STATES[current_state_name]
			elif was_my_turn and not feinting and current_state().next_state_on_hold:
				queued_action = current_state().fallback_state

		if queued_action in state_machine.states_map:

			if feinted_last:
				var particle_pos = get_hurtbox_center_float()
				spawn_particle_effect(preload("res://fx/FeintEffect.tscn"), particle_pos)
			state_machine._change_state(queued_action, queued_data)
			if not current_state().is_hurt_state:
				hitlag_ticks = 0
			if pressed_feint:
				feinting = true
				current_state().feinting = true

	queued_action = null
	queued_data = null
	queued_extra = null
	was_my_turn = false
	lowest_tick = current_state().current_real_tick

func toggle_quit_graphic(on = null):
	if on == null:
		quitter_label.visible = not quitter_label.visible
		if quitter_label.visible:
			play_sound("QuitterSound")
	else :
		quitter_label.visible = on
		if on:
			play_sound("QuitterSound")

func get_sadness_distance_penalty():
	if combo_count > 0 or opponent.is_in_hurt_state(false):
		return 1
	var pos = obj_local_center(opponent)
	var amount = 0
	if pos.y > 0:
		var dist = str(pos.y)
		amount = fixed.round(fixed.div(dist, DISTANCE_EXTRA_SADNESS))

	return 1 + amount

func tick():
	if hitlag_ticks > 0:
		if can_nudge:
			if fixed.round(fixed.mul(fixed.vec_len(current_nudge.x, current_nudge.y), "100.0")) > 1:
				current_nudge = fixed.vec_mul(current_nudge.x, current_nudge.y, nudge_amount)
				var di_scaled = get_scaled_di(current_di)
				var di_scaling = fixed.round(get_di_scaling())

				var particle = preload("res://fx/NudgeIndicator.tscn") if di_scaling <= 2 else preload("res://fx/NudgeIndicatorStrong.tscn")
				spawn_particle_effect(particle, Vector2(get_pos().x, get_pos().y + hurtbox.y), Vector2(di_scaled.x, di_scaled.y).normalized())

				move_directly(current_nudge.x, current_nudge.y if not is_grounded() else "0")
			can_nudge = false
		hitlag_ticks -= 1
		if hitlag_ticks == 0:
			if state_hit_cancellable:
				state_interruptable = true
				can_nudge = false
	else :
		if parried:

			parried = false
			if current_state().get("parry_active"):
				current_state().parry_active = false
			var prev = previous_state()
			if prev and prev.get("parry_active"):
				prev.parry_active = false
		var minus_offset = 0 if id == 1 else 1
		state_tick()

		if state_hit_cancellable:
			state_interruptable = true
			can_nudge = false
		if not current_state() is ThrowState and current_state().apply_pushback:
			chara.apply_pushback(get_opponent_dir())
		if is_grounded():
			used_air_dodge = false
			refresh_air_movements()
		current_tick += 1
		if not (current_state().is_hurt_state) and not (opponent.current_state().is_hurt_state):
			var x_vel_int = chara.get_x_vel_int()
			if Utils.int_sign(x_vel_int) == Utils.int_sign(opponent.get_pos().x - get_pos().x):
				gain_super_meter(Utils.int_max(Utils.int_abs(x_vel_int) / VEL_SUPER_GAIN_DIVISOR, 1))
	
	
	if state_interruptable:
		update_grounded()

	if hit_during_armor:
		has_hyper_armor = false
		hit_during_armor = false
	gain_burst_meter()
	update_data()
	if current_state().beats_backdash:
		buffer_moved_forward = true
	if current_state().backdash_iasa:
		buffer_moved_backward = true
	for particle in particles.get_children():
		particle.tick()
	any_available_actions = true
	last_vel = get_vel()
	var pos = get_pos()





	if not is_in_hurt_state() and not opponent.is_in_hurt_state() and combo_count <= 0 and penalty_ticks <= 0:

		var dir = fixed.sign(last_vel.x)
		var opp_dir = get_opponent_dir()
		if dir != 0 and dir != opp_dir and current_tick % 3 == 0:
			add_penalty(1)
		if dir != 0 and dir == opp_dir and current_tick % 4 == 0:
			if fixed.gt(fixed.abs(last_vel.x), "0.01"):
				add_penalty( - 1)
		if current_tick % 7 == 0:
			add_penalty(get_sadness_distance_penalty())
	









	
	last_pos = pos
	if penalty_ticks > 0:
		penalty_ticks -= 1
		if current_tick % 3 == 0:
			take_damage(2, 1)
	
	touching_wall = false
	var col_box = get_collision_box()
	var vel = last_vel
	if (col_box.x1 <= - stage_width and fixed.lt(vel.x, "0")):
		touching_wall = true
	if (col_box.x2 >= stage_width and fixed.gt(vel.x, "0")):
		touching_wall = true
	if not is_grounded():
		last_aerial_vel = last_vel
	if not (previous_state() is ParryState) or not (current_state() is ParryState):
		parried_last_state = false

	if forfeit:
		forfeit_ticks += 1
	if forfeit and forfeit_ticks > 2:
		change_state("ForfeitExplosion")
		forfeit = false
	if ReplayManager.playback:
		if "emotes" in ReplayManager.frames:
			if current_tick in ReplayManager.frames.emotes[id]:
				emote(ReplayManager.frames.emotes[id][current_tick])

func get_move_dir():
	return fixed.sign(last_vel.x)

























func add_penalty(amount):
	if not sadness_enabled:
		return 
	if amount > 0:
		var opp_pos = obj_local_center(opponent)
		var opp_dist = fixed.vec_len(str(opp_pos.x), str(opp_pos.y))
		if fixed.lt(opp_dist, MIN_DIST_SADNESS):
			return 
		

	penalty += amount
	if penalty > MAX_PENALTY:
		supers_available = 0
		super_meter = 0
		penalty = 0
		penalty_buffer = 0
		penalty_ticks = PENALTY_TICKS
		had_sadness = true
	if penalty < MIN_PENALTY:
		penalty = MIN_PENALTY

func reset_penalty():
	penalty = 0

func is_in_hurt_state(count_all = true):
	var state = current_state()
	if count_all:
		return state.busy_interrupt_type == CharacterState.BusyInterrupt.Hurt or state.is_hurt_state
	else :
		return state.is_hurt_state

func set_ghost_colors():
	if not ghost_ready_set and (state_interruptable or dummy_interruptable or ghost_ready_tick != null):

		var first_color = Color.green
		var second_color = Color.orange
		ghost_ready_set = true
		if opponent.ghost_ready_tick == null or opponent.ghost_ready_tick == ghost_ready_tick:
			set_color(first_color)
			if opponent.current_state().interruptible_on_opponent_turn or opponent.feinting or opponent.current_state().started_during_combo:
				opponent.ghost_ready_set = true
				opponent.set_color(first_color)
		elif ghost_ready_tick != null and opponent.ghost_ready_tick < ghost_ready_tick:
			set_color(second_color)

func set_facing(facing:int, force = false):
	if reverse_state and not force:
		facing *= - 1
	.set_facing(facing)

func update_facing():
	if obj_data.position_x < opponent.obj_data.position_x:
		set_facing(1)
	elif obj_data.position_x > opponent.obj_data.position_x:
		set_facing( - 1)
	if initialized:
		update_data()

func on_state_interruptable(state):
	if not dummy:
		state_interruptable = true
		was_my_turn = true
	else :
		dummy_interruptable = true
		refresh_prediction = true


func on_state_hit_cancellable(state):
	if not dummy:
		state_hit_cancellable = true
		refresh_prediction = true

func on_action_selected(action, data, extra):


	if you_label.visible:
		you_label.hide()
	queued_action = action
	queued_data = data
	queued_extra = extra
	state_interruptable = false
	state_hit_cancellable = false
	if action == "Undo":
		emit_signal("undo")


	var state = state_machine.get_state(action)
	if state:
		if not state.is_usable():
			action = "Forfeit"
	emit_signal("action_selected", action, data, extra)

func forfeit():
	will_forfeit = true

func _draw():





	pass

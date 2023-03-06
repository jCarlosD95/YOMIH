extends BaseProjectile

var aim_ticks = 60
var self_ = false

const MAX_WIDTH = 32

export  var body_target_texture:Texture

onready var line_drawer = $Flip / LineDrawer
onready var beep = $Sounds / Beep

func tick():
	.tick()
	if current_state().name == "Default":
		line_drawer.width = min((current_state().current_tick / float(aim_ticks)) * MAX_WIDTH, MAX_WIDTH)
		line_drawer.color = Color("88ff333d")
		beep.pitch_scale_ = lerp(1.5, 3.0, current_state().current_tick / float(85))
	elif current_state().name == "Fire":
		line_drawer.color = Color("94e4ff")
		line_drawer.width = max(62 - (current_state().current_tick * 5), 0)

func _process(delta):
	update()

func _draw():
	if disabled:
		line_drawer.width = 0
		return 
	if creator and creator.opponent and current_state().name == "Default" and Utils.pulse(0.15, 0.65):
		draw_texture(body_target_texture, to_local(creator.opponent.get_center_position_float()) - Vector2(64, 64))

func disable():
	.disable()
	creator.loic_draining = false

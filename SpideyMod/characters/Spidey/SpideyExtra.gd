extends PlayerExtra

onready var pull_button = $"%PullButton"

onready var detach_button = $"%DetachButton"

func _ready():

	pull_button.connect("toggled", self, "_on_bomb_button_toggled")
	detach_button.connect("toggled", self, "_on_bomb_button_toggled")



func show_options():
	pull_button.hide()
	detach_button.hide()
	pull_button.set_pressed_no_signal(fighter.pulling)
	detach_button.set_pressed_no_signal(false)

	var obj = fighter.obj_from_name(fighter.grappling_hook_projectile)
	if obj and obj.is_locked:
		pull_button.show()
	if obj:
		detach_button.show()

func get_extra():
	var extra = {
		"pull":pull_button.pressed, 
		"detach":detach_button.pressed
	}
	return extra


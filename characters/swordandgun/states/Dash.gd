extends CharacterState

export  var startup_invuln = true

func _enter():
	if host.reverse_state:
		beats_backdash = false
		backdash_iasa = true
	else :
		beats_backdash = true
		backdash_iasa = false

func _frame_0():
	host.move_directly(0, - 1)
	host.set_grounded(false)
	if startup_invuln and host.initiative:
		host.start_invulnerability()

func _frame_4():
	host.end_invulnerability()

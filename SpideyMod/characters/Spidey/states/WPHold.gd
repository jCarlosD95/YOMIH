extends ThrowState
	
func _exit():
#	#Pushes opponent towards Spidey
#	if host.get_facing() == "Right":
#		host.opponent.apply_force_relative(1,1)
#	else:
#		host.opponent.apply_force_relative(-1,1)
	_release()

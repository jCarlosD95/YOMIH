extends CharacterState

func _enter():
	._enter()
	host.clipping_wall = true
	host.colliding_with_opponent = false
	
	#upon entering the "WallCling" state, update the x,y coordinates where
	#character first hit the wall and must cling to it
	host.cling_x = host.get_pos().x
	host.cling_y = host.get_pos().y	
	
	host.air_movements_left = 4;
	host.change_stance_to("WallCling")


func _tick():
	#Every frame, reset character's position to where they first hit the wall
	host.set_pos(host.cling_x, host.cling_y)

	
	

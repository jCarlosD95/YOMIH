extends DefaultFireball
var stateName = ""

func _enter():
	stateName = host.creator.current_state().name
	host.creator.web_anchor = host.obj_name
	
#
func _tick():
	if host.creator.current_state().name != stateName:
		host.creator.web_anchor = null
		host.disable()

extends BaseProjectile

func disable():
	.disable()
	creator.after_image_object = null

func _ready():
	connect("got_hit", self, "on_got_hit")

func on_got_hit():
	disable()

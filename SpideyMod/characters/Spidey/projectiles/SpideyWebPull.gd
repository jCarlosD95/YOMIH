extends BaseProjectile

signal lasso_hit(obj)

func _ready():
	pass

func disable():
	.disable()
	creator.lasso_projectile = null

func hit(obj):
	emit_signal("lasso_hit", obj)

func update_rotation():
	var pos = creator.get_center_position_float()
	sprite.rotation = to_local(pos).angle()
	print_debug(to_local(pos).angle())

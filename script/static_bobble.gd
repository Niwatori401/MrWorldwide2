extends StaticBody2D
signal added_to_tree

var bobble_type : int;
var pixel_radius : float;

func _enter_tree():
	emit_signal("added_to_tree");

func scale_bobble():
	var original_size = $CollisionShape.shape.get_rect().size * global_scale * $CollisionShape.global_scale;
	var scale_multiplier_x = pixel_radius / (original_size[0] / 2);
	var scale_multiplier_y = pixel_radius / (original_size[1] / 2);
	
	$CollisionShape.scale = Vector2(scale_multiplier_x, scale_multiplier_y);

func pop():
	queue_free();

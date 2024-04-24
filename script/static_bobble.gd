extends StaticBody2D

var bobble_type : int;


func scale_bobble(pixel_radius):
	var original_size = $CollisionShape.shape.get_rect().size;
	var scale_multiplier_x = pixel_radius / (original_size[0] / 2);
	var scale_multiplier_y = pixel_radius / (original_size[1] / 2);
	
	$CollisionShape.scale = Vector2(scale_multiplier_x, scale_multiplier_y);

func pop():
	queue_free();

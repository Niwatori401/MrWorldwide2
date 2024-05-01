extends StaticBody2D
signal added_to_tree;
signal popped;

var bobble_type : String;
var pixel_radius : float;

func _enter_tree():
	emit_signal("added_to_tree");

func scale_bobble():
	var original_size = $CollisionShape.shape.get_rect().size * global_scale * $CollisionShape.global_scale;
	var scale_multiplier_x = pixel_radius / (original_size[0] / 2);
	var scale_multiplier_y = pixel_radius / (original_size[1] / 2);
	
	$CollisionShape.scale = Vector2(scale_multiplier_x, scale_multiplier_y);

func pop():
	emit_signal("popped");
	queue_free();


func get_food_texture() -> Texture2D:
	return $CollisionShape/Food.texture;
	
func set_food_texture(texture : Texture2D) -> void:
	$CollisionShape/Food.texture = texture;
	
func get_shell_texture() -> Texture2D:
	return $CollisionShape/Shell.texture;
	
func set_shell_texture(texture : Texture2D) -> void:
	$CollisionShape/Shell.texture = texture;
	
func get_food_scale() -> Vector2:
	return $CollisionShape/Food.scale;

func set_food_scale(new_scale : Vector2) -> void:
	$CollisionShape/Food.scale = new_scale;
	
func get_shell_scale() -> Vector2:
	return $CollisionShape/Shell.scale;
	
func set_shell_scale(new_scale : Vector2) -> void:
	$CollisionShape/Shell.scale = new_scale;

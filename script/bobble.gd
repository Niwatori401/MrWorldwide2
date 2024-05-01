extends RigidBody2D

signal impacted(bobble)

@export var bobble_type : String;

var already_impacted = false;

func scale_bobble(pixel_radius):
	var original_size = $CollisionShape.shape.get_rect().size * $CollisionShape.global_scale;
	var scale_multiplier_x = pixel_radius / (original_size[0] / 2);
	var scale_multiplier_y = pixel_radius / (original_size[1] / 2);
	
	$CollisionShape.scale = Vector2(scale_multiplier_x, scale_multiplier_y);


func set_velocity(velocity_vector):
	self.set_linear_velocity(velocity_vector);


func _on_body_entered(body):	
	if already_impacted:
		return;
	if body.is_in_group("ballstop"):
		already_impacted = true;
		impacted.emit(self);
		
func pop():
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

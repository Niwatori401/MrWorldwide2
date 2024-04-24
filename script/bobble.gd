extends RigidBody2D

signal impacted(bobble)

@export var bobble_type : int;

var already_impacted = false;

func scale_bobble(pixel_radius):
	var original_size = $CollisionShape.shape.get_rect().size;
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
	

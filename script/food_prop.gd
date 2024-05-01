extends RigidBody2D

signal impacted(bobble)

const FOOD_SCALE_MULTIPLIER = 0.7;

@export var bobble_type : String;

func scale_bobble(pixel_radius):
	var original_size = $CollisionShape/Food.global_scale * $CollisionShape/Food.get_rect().size;
	
	var scale_multiplier_x = pixel_radius / (original_size[0] / 2);
	var scale_multiplier_y = pixel_radius / (original_size[1] / 2);
	
	$CollisionShape.scale = FOOD_SCALE_MULTIPLIER * Vector2(scale_multiplier_x, scale_multiplier_y);

func copy_bobble_textures(bobble):
	$CollisionShape/Food.texture = bobble.get_child(0).get_child(1).texture;

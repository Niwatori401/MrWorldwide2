extends Node2D

signal impacted(bobble)

const FOOD_SCALE_MULTIPLIER = 0.3;
const SHELL_SCALE_MULTIPLIER = 0.04;

@export var bobble_type : String;

func scale_bobble(pixel_radius):
	var original_size = $CollisionShape.shape.get_rect().size * $CollisionShape.global_scale;
	
	var scale_multiplier_x = pixel_radius / (original_size[0] / 2);
	var scale_multiplier_y = pixel_radius / (original_size[1] / 2);
	
	$CollisionShape.scale = Vector2(scale_multiplier_x, scale_multiplier_y);

func copy_bobble_textures(bobble):
	$CollisionShape/Shell.texture = bobble.get_shell_texture();
	$CollisionShape/Food.texture = bobble.get_food_texture();


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

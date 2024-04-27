extends Node2D

@export var point_thresholds : Array[int];

func _ready():
	assert(point_thresholds.size() == $Sprite.sprite_frames.get_animation_names().size());
	$Sprite.play("0");

func _process(delta):
	pass

func update_scale():
	var target_resolution : Vector2 = get_viewport().get_window().size;
	var texture_size : Vector2 = $Sprite.sprite_frames.get_frame_texture("0", 0).get_size();
	var scale_factor : Vector2 = Vector2(target_resolution[0] / texture_size[0], target_resolution[1] / texture_size[1]);
	scale = scale_factor;
	
func center_on_screen():
	var target_resolution : Vector2 = get_viewport().get_window().size;
	global_position = Vector2(target_resolution[0]/2, target_resolution[1]/2);

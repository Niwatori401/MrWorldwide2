extends Node2D

# Point thresholds represent the max score for a given weight
# Must be in least to greatest order
@export var point_thresholds : Array[int];
@export var character_sprites : Array[Texture2D];

func _ready():
	assert(point_thresholds.size() == character_sprites.size());
	
	# Assign Textures to Sprite Frames
	for i in range(point_thresholds.size()):
		$Sprite.sprite_frames.add_animation("%s" % [i]);
		$Sprite.sprite_frames.add_frame("%s" % [i], character_sprites[i]);

	$Sprite.play("0");

func _process(_delta):
	pass

func update_scale():
	var target_resolution : Vector2 = get_viewport().get_window().size;
	
	for a in $Sprite.sprite_frames.get_animation_names():
		print($Sprite.sprite_frames.get_frame_texture(a, 0));
	
	var texture_size : Vector2 = $Sprite.sprite_frames.get_frame_texture("0", 0).get_size();
	var scale_factor : Vector2 = Vector2(target_resolution[0] / texture_size[0], target_resolution[1] / texture_size[1]);
	scale = scale_factor;
	
func center_on_screen():
	var target_resolution : Vector2 = get_viewport().get_window().size;
	global_position = Vector2(target_resolution[0]/2, target_resolution[1]/2);

func set_sprite_stage_by_points(points):
	for index in range(point_thresholds.size()):
		if points < point_thresholds[index]:
			if ("%s" % [index]) == $Sprite.animation:
				return;
			
			$Sprite.play("%s" % index);
			return;
	
	$Sprite.play("%s" % [point_thresholds.size() - 1])

func get_next_stage_threshold(cur_points) -> String:
	for value in point_thresholds:
		if cur_points < value:
			return "%s" % [value];
			
	return "∞";

extends Node2D

@export var background_image : Texture2D;
@export var music_stages : Array[AudioStream];

const MUTE = false;
var cur_points : int = 0;
const POINTS_PER_BOBBLE : int = 2;

# Called when the node enters the scene tree for the first time.
func _ready():
	if MUTE:
		AudioServer.set_bus_volume_db(0, -100);
	
	init_stage_bg();
	$Character.update_scale();
	$Character.center_on_screen();
	$Character.set_sprite_stage_by_points(cur_points);
	assert($Character.get_stage_count() == music_stages.size());
	update_score_text();
	update_music();
	
	

func on_bobble_popped():
	cur_points += POINTS_PER_BOBBLE;
	update_score_text();
	$Character.set_sprite_stage_by_points(cur_points);
	update_music();

func update_score_text():
	$ScoreLabel.text = "[center]%s / %s[/center]" % [cur_points, $Character.get_next_stage_threshold(cur_points)];

func update_music():
	var music_index = $Character.get_stage_index(cur_points);
	
	if $BGM.stream == null:
		$BGM.stream = music_stages[music_index];
		$BGM.stream.loop = true;
		$BGM.play();
		return;
		
	var current_position = $BGM.get_playback_position();
	$BGM.stream = music_stages[music_index];
	$BGM.stream.loop = true;
	$BGM.play(current_position);

# TODO: Add something for when you lose
func game_over():
	print("Game Over - Level")

func init_stage_bg():
	$Background.texture = background_image;
	
	#Update Scale
	var target_resolution : Vector2 = get_viewport_rect().size
	
	var texture_size : Vector2 = $Background.texture.get_size();

	var scale_factor : Vector2 = Vector2(target_resolution[0] / texture_size[0], target_resolution[1] / texture_size[1]);
	$Background.global_scale = scale_factor;
	
	# center_on_screen
	$Background.global_position = Vector2(target_resolution[0]/2, target_resolution[1]/2);


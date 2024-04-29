extends Node2D

@export var background_image : Texture2D;
@export var music_stages : Array[AudioStream];

var cur_points : int = 0;
const POINTS_PER_BOBBLE : int = 20;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Character.update_scale();
	$Character.center_on_screen();
	$Character.set_sprite_stage_by_points(cur_points);
	assert($Character.get_stage_count() == music_stages.size());
	update_score_text();
	update_music();

func on_bobble_popped():
	cur_points += 20;
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
	
	


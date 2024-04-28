extends Node2D

@export var background_image : Texture2D;

var cur_points : int = 0;
const POINTS_PER_BOBBLE : int = 20;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Character.update_scale();
	$Character.center_on_screen();
	update_score_text();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func on_bobble_popped():
	cur_points += 20;
	update_score_text();
	$Character.set_sprite_stage_by_points(cur_points);


func update_score_text():
	$ScoreLabel.text = "[center]%s / %s[/center]" % [cur_points, $Character.get_next_stage_threshold(cur_points)];

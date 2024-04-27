extends Node2D

@export var background_image : Texture2D;


# Called when the node enters the scene tree for the first time.
func _ready():
	$Character.update_scale();
	$Character.center_on_screen();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

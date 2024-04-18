extends RigidBody2D

signal impacted(bobble)

@export var bobble_type : String;


func _ready():
	pass

func _process(delta):
	pass

func _on_hit_box_body_entered(body):
	emit_signal("impacted", self);

func launch(velocity_vector):
	self.set_linear_velocity(velocity_vector);

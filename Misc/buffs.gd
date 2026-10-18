extends Area2D

@export var type : String

const SPRITE_CURA = preload("res://Sprites/icon.svg")
const SPRITE_BUFF = preload("res://Sprites/icon.svg")

func _ready() -> void:
	set_data()
	connect_signals()
	
func set_data() -> void:
	if type == "heal":
		%Sprite2D.texture = SPRITE_CURA
		
	if type == "buff":
		%Sprite2D.texture = SPRITE_BUFF
		
func connect_signals() -> void:
	connect("body_entered", collect)
	
func collect(body : Node2D) -> void:
	if body is CharacterBody2D:
		if type == "heal":
			print("H")
			
		if type == "buff":
			print("B")
			
		queue_free()
			

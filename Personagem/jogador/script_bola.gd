extends CharacterBody2D

var direcao := 1
var velocidade := 760.0
var tempo := 0.0

func _ready() -> void:
	$Sprite2D.flip_h = direcao < 0
	$AnimationPlayer.play("avançando")

func _physics_process(delta: float) -> void:
	tempo += delta
	if tempo >= 1.8:
		get_parent().queue_free()
		return
	var colisao := move_and_collide(Vector2(velocidade * direcao * delta, 0.0))
	if colisao != null:
		var corpo = colisao.get_collider()
		if corpo.has_method("receber_dano") and corpo.is_in_group("inimigos"):
			corpo.receber_dano(1, "bola")
		get_parent().queue_free()

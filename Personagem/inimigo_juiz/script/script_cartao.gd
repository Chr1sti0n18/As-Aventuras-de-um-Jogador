extends CharacterBody2D

var direcao := 1
var vermelho := false
var velocidade := 550.0
var tempo := 0.0
var consumido := false

func _ready() -> void:
	add_to_group("cartoes")
	$Sprite2D.flip_h = direcao < 0
	$AnimationPlayer.play("vermelho" if vermelho else "movendo")

func _physics_process(delta: float) -> void:
	tempo += delta
	if tempo >= 2.0:
		get_parent().queue_free()
		return
	var inicio := global_position
	var fim := inicio + Vector2(velocidade * direcao * delta, 0.0)
	var consulta := PhysicsRayQueryParameters2D.create(inicio, fim, 3)
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	if not impacto.is_empty():
		causar_dano_personagem(impacto.collider)
		get_parent().queue_free()
		return
	global_position = fim

func causar_dano_personagem(body: Node2D) -> void:
	if consumido:
		return
	if body.has_method("receber_dano") and body.is_in_group("jogador"):
		consumido = true
		body.receber_dano(1, 2.5 if vermelho else 0.0)
		get_parent().queue_free()

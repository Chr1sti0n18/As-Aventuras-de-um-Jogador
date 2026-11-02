extends "res://Personagem/inimigo_base.gd"

const CENA_CARTAO = preload("res://Personagem/inimigo_juiz/cena_cartao.tscn")
var direcao_inimigo := 1
@export var intervalo_entre_cartoes: float = 1.5
var proximo_vermelho := false
var tempo_ate_ataque := 0.45

func _ready() -> void:
	super._ready()
	som_dano = "dano_juiz"

func _physics_process(delta: float) -> void:
	atualizar_protecao(delta)
	tempo_ate_ataque = maxf(0.0, tempo_ate_ataque - delta)
	velocity.y += 1800.0 * delta
	move_and_slide()
	var jogador = Global.personagem
	if not is_instance_valid(jogador):
		return
	var distancia: float = jogador.global_position.x - global_position.x
	if absf(distancia) > 8.0:
		direcao_inimigo = 1 if distancia > 0.0 else -1
	$Sprite2D.flip_h = direcao_inimigo < 0
	$Marker2D.position = Vector2(64.0 * direcao_inimigo, 0.0)
	if jogador_perto() and absf(distancia) < 600.0 and absf(jogador.global_position.y - global_position.y) < 150.0:
		if not $AnimationPlayer.is_playing() or $AnimationPlayer.current_animation.begins_with("parado"):
			if tempo_ate_ataque <= 0.0:
				$AnimationPlayer.play("atirando_vermelho" if proximo_vermelho else "atirando_amarelo")
			else:
				$AnimationPlayer.play("parado_vermelho" if proximo_vermelho else "parado")
	else:
		$AnimationPlayer.play("parado_vermelho" if proximo_vermelho else "parado")
	alinhar_pes(63.0)

# Cada animacao chama o tiro com sua cor; a proxima e lembrada entre encontros.
func atirar_cartao(vermelho: bool = false) -> void:
	var jogador = Global.personagem
	if derrotado or not is_instance_valid(jogador) or not jogador_perto():
		return
	var distancia: float = jogador.global_position.x - global_position.x
	if absf(distancia) > 8.0:
		direcao_inimigo = 1 if distancia > 0.0 else -1
	$Sprite2D.flip_h = direcao_inimigo < 0
	$Marker2D.position.x = 64.0 * direcao_inimigo
	var cartao = CENA_CARTAO.instantiate()
	var corpo = cartao.get_node("CharacterBody2D")
	corpo.direcao = direcao_inimigo
	corpo.vermelho = vermelho
	proximo_vermelho = not vermelho
	# A preparacao de 0.4s completa o intervalo entre dois tiros.
	tempo_ate_ataque = maxf(0.0, intervalo_entre_cartoes - 0.4)
	# Configurar antes de add_child evita _ready com dados antigos.
	cartao.position = get_parent().to_local($Marker2D.global_position)
	get_parent().add_child(cartao)
	Global.tocar_som("ataque_juiz")

extends "res://Personagem/inimigo_base.gd"

enum Estado { GUARDA, PREPARANDO, MERGULHO, RECUPERANDO }
const LIMITE_DESLOCAMENTO_X := 2000.0
@export var tempo_preparacao: float = 0.3
@export var tempo_recuperacao: float = 0.7
@export var velocidade_mergulho: float = 820.0
@export var velocidade_aproximacao: float = 420.0
@export var duracao_mergulho: float = 0.65
var estado := Estado.GUARDA
var tempo_estado := 0.0
var direcao_inimigo2 := 1
var origem_x := 0.0
var espera_inicial := 0.35

func _ready() -> void:
	super._ready()
	som_dano = "dano_goleiro"
	origem_x = global_position.x
	$Aviso.visible = false

func _physics_process(delta: float) -> void:
	atualizar_protecao(delta)
	tempo_estado += delta
	velocity.y += 1800.0 * delta
	velocity.x = 0.0
	var jogador = Global.personagem
	if not is_instance_valid(jogador):
		return
	var distancia: float = jogador.global_position.x - global_position.x
	match estado:
		Estado.GUARDA:
			$AnimationPlayer.play("parado")
			if jogador_perto():
				if absf(distancia) > 8.0:
					direcao_inimigo2 = 1 if distancia > 0.0 else -1
				$Sprite2D.flip_h = direcao_inimigo2 < 0
				espera_inicial = maxf(0.0, espera_inicial - delta)
				if absf(distancia) < 440.0 and is_on_floor() and espera_inicial <= 0.0:
					mudar_estado(Estado.PREPARANDO)
				elif absf(distancia) > 120.0:
					var proximo_x := global_position.x + velocidade_aproximacao * direcao_inimigo2 * delta
					if absf(proximo_x - origem_x) < LIMITE_DESLOCAMENTO_X:
						velocity.x = velocidade_aproximacao * direcao_inimigo2
						$AnimationPlayer.play("correndo")
		Estado.PREPARANDO:
			# Direcao travada: cruzar por tras permite esquivar.
			$Sprite2D.region_rect = Rect2(73, 547, 214, 210)
			$Aviso.modulate.a = 0.55 + 0.45 * absf(sin(tempo_estado * 15.0))
			if tempo_estado >= tempo_preparacao:
				mudar_estado(Estado.MERGULHO)
				velocity.y = -170.0
		Estado.MERGULHO:
			velocity.x = velocidade_mergulho * direcao_inimigo2
			if tempo_estado >= duracao_mergulho or is_on_wall():
				mudar_estado(Estado.RECUPERANDO)
		Estado.RECUPERANDO:
			$Sprite2D.region_rect = Rect2(2009, 509, 237, 223)
			if tempo_estado >= tempo_recuperacao and is_on_floor():
				mudar_estado(Estado.GUARDA)
	move_and_slide()
	var limite_x := clampf(global_position.x, origem_x - LIMITE_DESLOCAMENTO_X, origem_x + LIMITE_DESLOCAMENTO_X)
	if not is_equal_approx(limite_x, global_position.x):
		global_position.x = limite_x
		if estado == Estado.MERGULHO:
			mudar_estado(Estado.RECUPERANDO)
	limitar_a_area()
	alinhar_pes(61.0)
	$Area2D.position.x = 28.0 * direcao_inimigo2
	if estado == Estado.MERGULHO and tempo_estado > 0.08:
		for body in $Area2D.get_overlapping_bodies():
			causar_dano_personagem(body)

func mudar_estado(novo: Estado) -> void:
	estado = novo
	tempo_estado = 0.0
	$Aviso.visible = estado == Estado.PREPARANDO
	$AnimationPlayer.stop()
	if estado == Estado.MERGULHO:
		Global.tocar_som("ataque_goleiro")
		$AnimationPlayer.play("atacando")

func causar_dano_personagem(body: Node2D) -> void:
	if derrotado or estado != Estado.MERGULHO:
		return
	if body.is_in_group("jogador") and not body.esta_deslizando():
		body.receber_dano(1)

func perseguir() -> void:
	pass # Ativacao por distancia, independente da camera.

func encerrar_perseguicao() -> void:
	pass

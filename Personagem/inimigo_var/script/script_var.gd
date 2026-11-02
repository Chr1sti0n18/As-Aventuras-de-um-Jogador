extends "res://Personagem/inimigo_base.gd"

const CENA_LASER = preload("res://Personagem/inimigo_var/cena_laser.tscn")
enum EstadoVoo { ALTO, DESCENDO, BRECHA, SUBINDO }
@export var quantidade_lasers: int = 2
@export var intervalo_entre_sequencias: float = 1.5
@export var duracao_brecha: float = 2.5
@export var elevacao_voo: float = 150.0
@export var velocidade_voo: float = 220.0
var estado_voo := EstadoVoo.ALTO
var ativo := false
var atacando := false
var altura_voo := 0.0
var origem_x := 0.0
var tempo_voo := 0.0
var tempo_estado := 0.0
var tempo_para_atacar := 1.2
var ponto_brecha := 0.0
var lado_patrulha := 1.0
var sequencias_concluidas := 0
var sequencia_em_andamento := false
var tempo_desde_ultimo_disparo := 0.0

func _ready() -> void:
	super._ready()
	som_dano = "dano_var"
	add_to_group("var")
	altura_voo = global_position.y
	origem_x = global_position.x
	ponto_brecha = origem_x
	global_position.y = altura_voo - elevacao_voo
	collision_layer = 0
	$Brecha.visible = false
	$AnimationPlayer.animation_finished.connect(_ao_terminar_animacao)
	$AnimationPlayer.play("parado")

func _physics_process(delta: float) -> void:
	atualizar_protecao(delta)
	tempo_voo += delta
	velocity = Vector2.ZERO
	var jogador = Global.personagem
	if not is_instance_valid(jogador):
		return
	ativo = jogador_perto()
	if not ativo:
		return
	tempo_estado += delta
	tempo_desde_ultimo_disparo += delta
	var distancia: float = jogador.global_position.x - global_position.x
	if absf(distancia) > 5.0:
		$Sprite2D.flip_h = distancia < 0.0
	match estado_voo:
		EstadoVoo.ALTO:
			global_position.y = altura_voo - elevacao_voo + sin(tempo_voo * 3.0) * 7.0
			if not atacando:
				var alvo := clampf(jogador.global_position.x + lado_patrulha * 145.0, origem_x - 440.0, origem_x + 440.0)
				mover_para_x(alvo, velocidade_voo, delta)
				if absf(global_position.x - alvo) < 12.0:
					lado_patrulha *= -1.0
				tempo_para_atacar -= delta
				$AnimationPlayer.play("correndo")
				if sequencias_concluidas >= 2 and not sequencia_em_andamento:
					ponto_brecha = clampf(jogador.global_position.x + lado_patrulha * 80.0, origem_x - 440.0, origem_x + 440.0)
					mudar_estado_voo(EstadoVoo.DESCENDO)
				elif tempo_para_atacar <= 0.0 and not sequencia_em_andamento:
					atacando = true
					$AnimationPlayer.play("atacando")
		EstadoVoo.DESCENDO:
			global_position.y = move_toward(global_position.y, altura_voo, 240.0 * delta)
			mover_para_x(ponto_brecha, 260.0, delta)
			$AnimationPlayer.play("correndo")
			if absf(global_position.y - altura_voo) < 1.0 and absf(global_position.x - ponto_brecha) < 5.0:
				mudar_estado_voo(EstadoVoo.BRECHA)
		EstadoVoo.BRECHA:
			# Paira baixo e previsivel durante uma janela curta para a pisada.
			global_position.y = altura_voo + sin(tempo_voo * 3.0) * 2.0
			$AnimationPlayer.play("parado")
			if tempo_estado >= duracao_brecha:
				mudar_estado_voo(EstadoVoo.SUBINDO)
		EstadoVoo.SUBINDO:
			global_position.y = move_toward(global_position.y, altura_voo - elevacao_voo, 280.0 * delta)
			$AnimationPlayer.play("correndo")
			if global_position.y <= altura_voo - elevacao_voo + 1.0:
				mudar_estado_voo(EstadoVoo.ALTO)
	move_and_slide()
	global_position.x = clampf(global_position.x, origem_x - 460.0, origem_x + 460.0)
	limitar_a_area()

func mover_para_x(alvo: float, velocidade_maxima: float, delta: float) -> void:
	velocity.x = clampf((alvo - global_position.x) / maxf(delta, 0.001), -velocidade_maxima, velocidade_maxima)

func mudar_estado_voo(novo: EstadoVoo) -> void:
	estado_voo = novo
	tempo_estado = 0.0
	$Brecha.visible = novo == EstadoVoo.BRECHA
	if novo == EstadoVoo.ALTO:
		sequencias_concluidas = 0
		sequencia_em_andamento = false
		tempo_para_atacar = 1.0
	# Fora da brecha o jogador atravessa o VAR: nao pode esperar em cima dele.
	set_deferred("collision_layer", 8 if novo == EstadoVoo.BRECHA else 0)

func receber_dano(quantidade: int = 1, origem: String = "bola") -> bool:
	if origem != "pisao" or estado_voo != EstadoVoo.BRECHA:
		return false
	var acertou := super.receber_dano(quantidade, origem)
	if acertou and not derrotado:
		mudar_estado_voo(EstadoVoo.SUBINDO)
	return acertou

func disparar_laser() -> void:
	var jogador = Global.personagem
	if derrotado or not ativo or estado_voo != EstadoVoo.ALTO or not is_instance_valid(jogador) or sequencia_em_andamento:
		return
	sequencia_em_andamento = true
	var centro_x: float = jogador.global_position.x
	var fase = get_tree().current_scene
	var som_emitido := false
	for i in quantidade_lasers:
		if derrotado or not ativo or estado_voo != EstadoVoo.ALTO:
			sequencia_em_andamento = false
			return
		var deslocamento := (i - (quantidade_lasers - 1) / 2.0) * 180.0
		var consulta := PhysicsRayQueryParameters2D.create(Vector2(centro_x + deslocamento, 200.0), Vector2(centro_x + deslocamento, 720.0), 1)
		var resultado := get_world_2d().direct_space_state.intersect_ray(consulta)
		if resultado.is_empty():
			continue
		if not som_emitido:
			Global.tocar_som("ataque_var")
			som_emitido = true
		var laser = CENA_LASER.instantiate()
		laser.emissor = self
		laser.position = resultado.position
		laser.z_index = 1
		fase.add_child(laser)
		tempo_desde_ultimo_disparo = 0.0
		if i < quantidade_lasers - 1:
			await get_tree().create_timer(0.15, false).timeout
			if not is_inside_tree():
				return
	sequencia_em_andamento = false
	if som_emitido:
		sequencias_concluidas += 1

func _ao_terminar_animacao(nome: StringName) -> void:
	if nome == &"atacando":
		atacando = false
		# A animacao prepara o proximo disparo durante 0.6 s.
		# Descontar essa preparacao mede o intervalo entre os lasers das sequencias.
		tempo_para_atacar = maxf(0.0, intervalo_entre_sequencias - 0.6 - tempo_desde_ultimo_disparo)

func perseguir() -> void:
	pass

func encerrar_perseguicao() -> void:
	pass

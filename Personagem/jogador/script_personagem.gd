extends CharacterBody2D

const CENA_BOLA = preload("res://Personagem/jogador/cena_bola.tscn")
enum Acao { LIVRE, CHUTE, CARRINHO }
var velocidade := 500.0
var gravidade := 1800.0
var forca_pulo := 800.0
var direcao := 1
var acao := Acao.LIVRE
var tempo_acao := 0.0
var intervalo_carrinho := 0.0
var tempo_lento := 0.0
var invulneravel := 0.0
var tween_dano: Tween
var atingidos: Dictionary = {}
var forma_carrinho := RectangleShape2D.new()

func _ready() -> void:
	Global.personagem = self
	add_to_group("jogador")
	forma_carrinho.size = Vector2(110.0, 44.0)
	$AnimationPlayer.animation_finished.connect(_ao_terminar_animacao)
	$Camera2D.limit_left = 0
	$Camera2D.limit_right = 13032
	$Camera2D.limit_top = 0
	$Camera2D.limit_bottom = 724
	get_window().size_changed.connect(ajustar_enquadramento)
	ajustar_enquadramento()

func ajustar_enquadramento() -> void:
	var tamanho := get_window().size
	# O modo expand preenche o monitor; enquadra tambem telas mais altas.
	var altura_visivel := maxf(720.0, 1280.0 * tamanho.y / maxf(tamanho.x, 1.0))
	var aproximacao := maxf(1.2, altura_visivel / 724.0)
	$Camera2D.zoom = Vector2.ONE * aproximacao

func _physics_process(delta: float) -> void:
	if Global.qtd_vidas <= 0:
		Global.finalizar_partida(false)
		return
	tempo_lento = maxf(0.0, tempo_lento - delta)
	invulneravel = maxf(0.0, invulneravel - delta)
	intervalo_carrinho = maxf(0.0, intervalo_carrinho - delta)
	tempo_acao += delta
	velocity.y += gravidade * delta
	var fator := 0.55 if tempo_lento > 0.0 else 1.0
	var eixo := Input.get_axis("ir_para_esquerda", "ir_para_direita")
	if acao == Acao.LIVRE:
		if eixo != 0.0:
			direcao = 1 if eixo > 0.0 else -1
		velocity.x = eixo * velocidade * fator
		if is_on_floor() and Input.is_action_just_pressed("carrinho") and intervalo_carrinho <= 0.0:
			iniciar_carrinho()
		elif is_on_floor() and Input.is_action_pressed("chutar"):
			acao = Acao.CHUTE
			tempo_acao = 0.0
			$AnimationPlayer.play("chutando")
		elif is_on_floor() and Input.is_action_just_pressed("pular"):
			velocity.y = -forca_pulo
			Global.tocar_som("pulo")
	elif acao == Acao.CHUTE:
		velocity.x = eixo * velocidade * 0.35 * fator
	else:
		velocity.x = direcao * 650.0 * fator
		if tempo_acao >= 0.65:
			encerrar_carrinho()
	$Sprite2D.flip_h = direcao < 0
	if acao == Acao.LIVRE:
		if not is_on_floor() or velocity.y < 0.0:
			$AnimationPlayer.play("pulando")
		else:
			$AnimationPlayer.play("correndo" if absf(velocity.x) > 0.0 else "parado")
	var estava_descendo := velocity.y > 0.0
	move_and_slide()
	for i in get_slide_collision_count():
		var colisao := get_slide_collision(i)
		var corpo = colisao.get_collider()
		if is_instance_valid(corpo) and corpo.is_in_group("var") and estava_descendo and colisao.get_normal().y < -0.5:
			if corpo.receber_dano(1, "pisao"):
				velocity.y = -560.0
				if acao == Acao.CARRINHO:
					encerrar_carrinho()
				break
	if esta_deslizando():
		atingir_com_carrinho()
	# Mantem os pes na mesma altura nos frames com tamanhos diferentes.
	$Sprite2D.position.y = 25.5 - $Sprite2D.region_rect.size.y * $Sprite2D.scale.y * 0.5
	$Camera2D.global_position.y = 362.0
	$Lentidao.visible = tempo_lento > 0.0

func iniciar_carrinho() -> void:
	Global.tocar_som("carrinho")
	acao = Acao.CARRINHO
	tempo_acao = 0.0
	atingidos.clear()
	$CollisionShape2D.set_deferred("disabled", true)
	$ColisaoCarrinho.set_deferred("disabled", false)
	$AnimationPlayer.play("carrinho")

func encerrar_carrinho() -> void:
	acao = Acao.LIVRE
	intervalo_carrinho = 0.45
	$CollisionShape2D.set_deferred("disabled", false)
	$ColisaoCarrinho.set_deferred("disabled", true)

func esta_deslizando() -> bool:
	return acao == Acao.CARRINHO and tempo_acao >= 0.10 and tempo_acao < 0.60

func atingir_com_carrinho() -> void:
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma_carrinho
	consulta.transform = Transform2D(0.0, global_position + Vector2(35.0 * direcao, 9.0))
	consulta.collision_mask = 4
	for resultado in get_world_2d().direct_space_state.intersect_shape(consulta):
		var inimigo = resultado.collider
		if inimigo.has_method("receber_dano") and not atingidos.has(inimigo.get_instance_id()):
			atingidos[inimigo.get_instance_id()] = true
			inimigo.receber_dano(1, "carrinho")

func receber_dano(quantidade: int = 1, duracao_lentidao: float = 0.0) -> bool:
	if Global.invencibilidade or Global.partida_encerrada or invulneravel > 0.0 or Global.qtd_vidas <= 0:
		return false
	Global.qtd_vidas = maxi(0, Global.qtd_vidas - quantidade)
	Global.tocar_som("dano")
	invulneravel = 0.4
	tempo_lento = maxf(tempo_lento, duracao_lentidao)
	piscar_vermelho()
	return true

func piscar_vermelho() -> void:
	if tween_dano != null:
		tween_dano.kill()
	tween_dano = create_tween()
	for i in 3:
		tween_dano.tween_property($Sprite2D, "modulate", Color(1.0, 0.2, 0.2), 0.08)
		tween_dano.tween_property($Sprite2D, "modulate", Color.WHITE, 0.08)

func _ao_terminar_animacao(nome: StringName) -> void:
	if nome == &"chutando" and acao == Acao.CHUTE:
		acao = Acao.LIVRE

func spawnar_bolar() -> void:
	if acao != Acao.CHUTE:
		return
	Global.tocar_som("chute")
	var bola = CENA_BOLA.instantiate()
	bola.get_node("CharacterBody2D").direcao = direcao
	bola.position = get_tree().current_scene.to_local(global_position + Vector2(48.0 * direcao, 5.0))
	get_tree().current_scene.add_child(bola)

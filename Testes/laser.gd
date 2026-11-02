extends SceneTree

var Global
var jogador: CharacterBody2D
var robo: CharacterBody2D
var verificacoes := 0
var falhas := 0

func _initialize() -> void:
	call_deferred("executar")

func esperar(tempo: float) -> void:
	await create_timer(tempo, true).timeout

func conferir(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("OK LASER: ", descricao)
	else:
		falhas += 1
		push_error("FALHOU LASER: " + descricao)

func posicionar(posicao: Vector2) -> void:
	jogador.global_position = posicao
	jogador.velocity = Vector2.ZERO
	jogador.invulneravel = 0.0
	Global.qtd_vidas = 100

func criar_laser() -> Node2D:
	var laser = load("res://Personagem/inimigo_var/cena_laser.tscn").instantiate()
	laser.emissor = robo
	laser.position = Vector2(500, 620)
	current_scene.add_child(laser)
	return laser

func limpar(laser: Node2D) -> void:
	if is_instance_valid(laser):
		laser.queue_free()
	await esperar(0.06)

func executar() -> void:
	Global = root.get_node("Global")
	Global.definir_som(false)
	Global.definir_invencibilidade(false)
	Global.iniciar_partida()
	while Global.mudando_cena:
		await process_frame
	for inimigo in get_nodes_in_group("inimigos"):
		inimigo.set_physics_process(false)
	jogador = Global.personagem
	# A gravidade zero permite testar corpos reais em alturas precisas.
	# A fisica do jogador continua contando a protecao entre acertos.
	jogador.gravidade = 0.0
	var emissor = load("res://Personagem/inimigo_var/cena_var.tscn").instantiate()
	emissor.position = Vector2(800, 535)
	current_scene.add_child(emissor)
	robo = emissor.get_node("CharacterBody2D")
	robo.set_physics_process(false)
	posicionar(Vector2(500, 594))
	var laser := criar_laser()
	await esperar(0.28)
	conferir(Global.qtd_vidas == 100 and not laser.feixe_ativo and not laser.perigoso, "mira de preparacao nao causa dano")
	await esperar(0.24)
	conferir(Global.qtd_vidas == 99 and laser.feixe_ativo and not laser.perigoso, "feixe causa dano antes de o circulo residual ser ativado")
	await esperar(0.16)
	conferir(laser.feixe_ativo and laser.perigoso and Global.qtd_vidas == 99, "feixe e circulo sobrepostos nao duplicam dano na protecao")
	conferir(jogador.tween_dano != null, "dano do laser usa o efeito vermelho do jogador")
	await limpar(laser)
	posicionar(Vector2(500, 420))
	laser = criar_laser()
	await esperar(0.53)
	conferir(Global.qtd_vidas == 99 and not laser.get_node("ZonaPerigo").overlaps_body(jogador), "feixe atinge o jogador no ar sem contato com o chao")
	await limpar(laser)
	posicionar(Vector2(500, 200))
	laser = criar_laser()
	await esperar(1.4)
	conferir(Global.qtd_vidas == 100, "jogador acima da altura visual do feixe fica seguro")
	await limpar(laser)
	posicionar(Vector2(700, 594))
	laser = criar_laser()
	await esperar(1.7)
	conferir(Global.qtd_vidas == 100, "fora do alcance lateral do laser e circulo nao ha dano")
	conferir(not laser.feixe_ativo and not laser.get_node("SpriteFeixe").visible and laser.perigoso, "circulo continua perigoso depois que o feixe termina")
	posicionar(Vector2(500, 594))
	await esperar(0.08)
	conferir(Global.qtd_vidas == 99, "pisar no circulo pos disparo causa dano sem espera de dois segundos")
	await esperar(0.12)
	conferir(Global.qtd_vidas == 99, "protecao temporaria evita perda de vidas a cada quadro")
	await esperar(0.42)
	conferir(Global.qtd_vidas < 99, "permanecer no circulo volta a causar dano apos a protecao")
	posicionar(Vector2(700, 594))
	await esperar(1.8)
	posicionar(Vector2(500, 594))
	await esperar(0.08)
	conferir(is_instance_valid(laser) and Global.qtd_vidas == 99, "circulo ainda visivel no fim da animacao continua causando dano")
	posicionar(Vector2(700, 594))
	await esperar(0.5)
	conferir(not is_instance_valid(laser), "laser e circulo desaparecem ao concluir a animacao")
	posicionar(Vector2(500, 594))
	await esperar(0.08)
	conferir(Global.qtd_vidas == 100, "nao sobra colisao perigosa depois da animacao")
	Global.definir_invencibilidade(true)
	laser = criar_laser()
	await esperar(0.7)
	conferir(Global.qtd_vidas == 100, "invencibilidade protege do feixe e do circulo")
	Global.definir_invencibilidade(false)
	await esperar(0.08)
	conferir(Global.qtd_vidas == 99, "desligar invencibilidade restaura dano do VAR")
	Global.pausar()
	var instante: float = laser.get_node("AnimationPlayer").current_animation_position
	var vidas: int = Global.qtd_vidas
	await esperar(0.25)
	conferir(is_equal_approx(instante, laser.get_node("AnimationPlayer").current_animation_position) and Global.qtd_vidas == vidas, "pausa congela animacao e dano do laser")
	Global.continuar()
	await esperar(0.1)
	conferir(laser.get_node("AnimationPlayer").current_animation_position > instante, "continuar retoma a animacao do laser")
	robo.vida = 1
	robo.mudar_estado_voo(robo.EstadoVoo.BRECHA)
	robo.receber_dano(1, "pisao")
	await esperar(0.06)
	conferir(not is_instance_valid(laser), "derrotar o emissor remove tambem as novas colisoes")
	Global.definir_invencibilidade(false)
	Global.definir_som(true)
	print("RESULTADO LASER: ", verificacoes, " verificacoes; ", falhas, " falhas")
	Global.encerrar_jogo(0 if falhas == 0 else 1)

extends SceneTree

var Global
var fase: Node2D
var jogador: CharacterBody2D
var falhas := 0
var verificacoes := 0

func _initialize() -> void:
	call_deferred("executar")

func esperar(tempo: float) -> void:
	await create_timer(tempo, true).timeout

func conferir(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("OK AREAS: ", descricao)
	else:
		falhas += 1
		push_error("FALHOU AREAS: " + descricao)

func concluir_troca() -> void:
	while Global.mudando_cena:
		await process_frame
	await esperar(0.08)

func posicionar(x: float) -> void:
	jogador.global_position = Vector2(x, 594)
	jogador.velocity = Vector2.ZERO

func limpar_area(indice: int) -> void:
	for inimigo in fase.inimigos_areas[indice]:
		if is_instance_valid(inimigo) and not inimigo.derrotado:
			inimigo.derrotar()

func executar() -> void:
	Global = root.get_node("Global")
	Global.definir_som(false)
	Global.definir_invencibilidade(true)
	Global.iniciar_partida()
	await concluir_troca()
	fase = current_scene
	jogador = Global.personagem
	for inimigo in get_nodes_in_group("inimigos"):
		inimigo.set_physics_process(false)
	conferir(fase.barreiras.size() == 3, "ha barreiras entre os quatro cenarios")
	conferir(fase.inimigos_restantes(0) == 2 and fase.inimigos_restantes(1) == 2 and fase.inimigos_restantes(2) == 2 and fase.inimigos_restantes(3) == 7, "inimigos distribuidos por area de origem: 2, 2, 2, 7")
	conferir(jogador.get_collision_mask_value(5) and fase.barreiras[0].bloqueada, "jogador colide com a primeira passagem bloqueada")
	# O goleiro do estadio deve conseguir perseguir alem do antigo alcance de 720.
	var goleiro = fase.get_node("Inimigos/Goleiro10/CharacterBody2D")
	goleiro.set_physics_process(true)
	for i in 300:
		posicionar(goleiro.global_position.x + 600.0)
		await physics_frame
	goleiro.set_physics_process(false)
	var distancia: float = goleiro.global_position.x - goleiro.origem_x
	conferir(distancia > 1900.0 and distancia <= 2000.0, "goleiro percorre quase 2000 pixels sem parar no antigo limite")
	goleiro.global_position.x = goleiro.origem_x
	posicionar(2100)
	await esperar(0.12)
	Input.action_press("ir_para_direita")
	await esperar(0.5)
	conferir(jogador.global_position.x < 2172, "andar nao atravessa uma area com inimigos vivos")
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	await esperar(0.85)
	conferir(jogador.global_position.x < 2172, "pular nao permite ultrapassar a barreira")
	Input.action_press("carrinho")
	await esperar(0.05)
	Input.action_release("carrinho")
	await esperar(0.7)
	conferir(jogador.global_position.x < 2172, "carrinho tambem respeita a barreira")
	Input.action_release("ir_para_direita")
	var juiz = fase.get_node("Inimigos/Juiz01/CharacterBody2D")
	juiz.receber_dano(1)
	await esperar(0.04)
	conferir(fase.inimigos_restantes(0) == 2 and fase.barreiras[0].bloqueada, "machucar um inimigo nao libera a area")
	juiz.protecao = 0.0
	juiz.receber_dano(1)
	await esperar(0.04)
	conferir(fase.inimigos_restantes(0) == 1 and fase.barreiras[0].bloqueada, "passagem continua fechada com um inimigo restante")
	var ultimo = fase.get_node("Inimigos/Goleiro02/CharacterBody2D")
	ultimo.global_position.x = 2500
	conferir(ultimo.area_origem == 0 and fase.inimigos_restantes(0) == 1, "movimento nao transfere inimigo para outra contagem")
	ultimo.set_physics_process(true)
	await esperar(0.06)
	ultimo.set_physics_process(false)
	conferir(ultimo.global_position.x < 2172, "goleiro fica acessivel dentro da area de origem")
	ultimo.derrotar()
	await esperar(0.05)
	conferir(fase.inimigos_restantes(0) == 0 and not fase.barreiras[0].bloqueada, "ultimo inimigo derrotado libera passagem antes do fim do desaparecimento")
	Input.action_press("ir_para_direita")
	for i in 90:
		await physics_frame
		if jogador.global_position.x > 2250:
			break
	Input.action_release("ir_para_direita")
	await esperar(0.05)
	conferir(jogador.global_position.x > 2172 and fase.barreiras[0].bloqueada, "entra na segunda area e a passagem fecha atras com o jogador fora da parede")
	Input.action_press("ir_para_esquerda")
	await esperar(0.4)
	Input.action_release("ir_para_esquerda")
	conferir(jogador.global_position.x > 2172, "retornar tambem exige limpar a area atual")
	var var_inimigo = fase.get_node("Inimigos/Var04/CharacterBody2D")
	var_inimigo.mudar_estado_voo(var_inimigo.EstadoVoo.BRECHA)
	var_inimigo.receber_dano(1, "pisao")
	fase.get_node("Inimigos/Juiz03/CharacterBody2D").derrotar()
	await esperar(0.05)
	conferir(var_inimigo.vida == 1 and not fase.pode_atravessar(4344.0, true), "VAR com uma vida restante mantem o viaduto bloqueado")
	var_inimigo.derrotar()
	await esperar(0.05)
	conferir(not fase.barreiras[0].bloqueada and not fase.barreiras[1].bloqueada, "limpar segunda area libera avancar e retornar")
	posicionar(4140)
	await esperar(0.1)
	Input.action_press("ir_para_direita")
	var viaduto = fase.get_node("TransicaoViaduto")
	for i in 90:
		await physics_frame
		if viaduto.transicionando:
			break
	conferir(viaduto.transicionando and paused, "viaduto so inicia o fade depois que a area foi limpa")
	await esperar(0.9)
	Input.action_release("ir_para_direita")
	conferir(jogador.global_position.x > 4344 and not paused, "viaduto continua funcionando com as barreiras")
	posicionar(6300)
	await esperar(0.1)
	Input.action_press("ir_para_direita")
	await esperar(0.6)
	Input.action_release("ir_para_direita")
	var tunel = fase.get_node("TransicaoEstadio")
	conferir(jogador.global_position.x < 6516 and not tunel.transicionando and not paused, "entrada do estadio nao pode iniciar fade com inimigos vivos")
	tunel.atravessar(tunel.Lado.CAMPO)
	conferir(not tunel.transicionando, "chamar a transicao diretamente tambem respeita o bloqueio")
	limpar_area(2)
	await esperar(0.05)
	Input.action_press("ir_para_direita")
	for i in 90:
		await physics_frame
		if tunel.transicionando:
			break
	conferir(tunel.transicionando, "limpar entrada libera o tunel")
	await esperar(0.9)
	Input.action_release("ir_para_direita")
	conferir(jogador.global_position.x > 6516 and fase.inimigos_restantes(3) == 7, "estadio conserva seus sete inimigos")
	tunel.atravessar(tunel.Lado.EXTERIOR)
	conferir(not tunel.transicionando, "nao sai do estadio enquanto houver inimigos nele")
	posicionar(12560)
	await esperar(0.1)
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	await esperar(0.85)
	conferir(not Global.partida_encerrada and not fase.get_node("Taca").coletada, "taca nao encerra partida antes de limpar o estadio")
	for inimigo in fase.inimigos_areas[3]:
		if inimigo != fase.get_node("Inimigos/Goleiro13/CharacterBody2D"):
			inimigo.derrotar()
	await esperar(0.2)
	conferir(fase.inimigos_restantes(3) == 1 and not fase.pode_coletar_taca(), "goleiro depois da taca tambem precisa ser derrotado")
	posicionar(12560)
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	var taca = fase.get_node("Taca")
	for i in 40:
		await physics_frame
		if taca.overlaps_body(jogador):
			break
	conferir(taca.overlaps_body(jogador) and not taca.coletada, "contato com a taca permanece bloqueado pelo ultimo inimigo")
	fase.get_node("Inimigos/Goleiro13/CharacterBody2D").derrotar()
	await esperar(0.65)
	conferir(Global.tela_atual == Global.Tela.VITORIA, "ultimo inimigo libera a coleta sem exigir sair e entrar de novo na taca")
	Global.iniciar_partida()
	await concluir_troca()
	fase = current_scene
	conferir(fase.barreiras[0].bloqueada and fase.inimigos_restantes(0) == 2 and Global.qtd_vidas == 5, "reiniciar restaura inimigos, barreiras e cinco vidas")
	Global.definir_invencibilidade(false)
	Global.definir_som(true)
	print("RESULTADO AREAS: ", verificacoes, " verificacoes; ", falhas, " falhas")
	Global.encerrar_jogo(0 if falhas == 0 else 1)

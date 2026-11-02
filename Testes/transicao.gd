extends Node2D

var falhas := 0
var verificacoes := 0
var iniciadas := 0
var concluidas := 0

func verificar(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("OK: ", descricao)
	else:
		falhas += 1
		push_error("FALHOU: " + descricao)

func esperar(tempo: float) -> void:
	await get_tree().create_timer(tempo, true).timeout

func _ready() -> void:
	var fase = load("res://Cenario/cena_fase.tscn").instantiate()
	fase.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fase)
	# Este teste isola os fades; o bloqueio por combate e exercitado em areas.gd.
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		inimigo.derrotar()
	var jogador = Global.personagem
	var passagem = fase.get_node("TransicaoEstadio")
	var camera: Camera2D = jogador.get_node("Camera2D")
	passagem.transicao_iniciada.connect(func(): iniciadas += 1)
	passagem.transicao_concluida.connect(func(): concluidas += 1)
	await esperar(0.12)
	verificar(camera.limit_right == 4344 and camera.limit_left == 0, "cidade nao mostra a emenda do viaduto antes da passagem")
	verificar(not passagem.get_node("Tela").visible, "tela de transicao comeca escondida")
	jogador.global_position.x = 6300.0
	await esperar(0.05)
	Input.action_press("ir_para_direita")
	for i in 90:
		await get_tree().physics_frame
		if passagem.transicionando:
			break
	verificar(passagem.transicionando and get_tree().paused, "entrada pausa combate e movimento")
	var x_pausado: float = jogador.global_position.x
	var vidas: int = Global.qtd_vidas
	await esperar(0.1)
	verificar(is_equal_approx(jogador.global_position.x, x_pausado), "jogador nao anda durante o escurecimento")
	verificar(passagem.get_node("Tela/Escurecimento").modulate.a > 0.0, "tela escurece gradualmente")
	await esperar(0.2)
	verificar(passagem.get_node("Tela/Escurecimento").modulate.a > 0.99, "tela cobre a troca de ambiente")
	verificar(jogador.global_position.x > 6516 and camera.limit_left == 6516, "jogador e camera passam ao campo sob a cobertura")
	await esperar(0.55)
	verificar(not get_tree().paused and not passagem.transicionando, "combate e controles retomam apos revelar o campo")
	verificar(Global.qtd_vidas == vidas, "passagem nao causa dano ao jogador")
	verificar(jogador.global_position.x > 6596, "direita mantida continua andando ao sair")
	verificar(iniciadas == 1 and concluidas == 1, "entrada dispara uma unica transicao")
	Input.action_release("ir_para_direita")
	Input.action_press("ir_para_esquerda")
	for i in 90:
		await get_tree().physics_frame
		if passagem.transicionando:
			break
	verificar(passagem.transicionando, "retorno tambem aciona o tunel")
	await esperar(0.9)
	Input.action_release("ir_para_esquerda")
	verificar(jogador.global_position.x < 6516 and camera.limit_right == 6516 and camera.limit_left == 4344, "retorno revela o exterior sem mostrar nenhuma das emendas")
	await esperar(0.3)
	verificar(iniciadas == 2 and concluidas == 2 and not get_tree().paused, "passagem nao se repete com jogador parado")
	verificar(not passagem.get_node("Tela").visible, "cobertura some ao terminar")
	await testar_viaduto(fase, jogador, camera)
	print("RESULTADO TRANSICAO: ", verificacoes, " verificacoes; ", falhas, " falhas")
	Global.encerrar_jogo(0 if falhas == 0 else 1)

func testar_viaduto(fase: Node2D, jogador: CharacterBody2D, camera: Camera2D) -> void:
	var viaduto = fase.get_node("TransicaoViaduto")
	var estadio = fase.get_node("TransicaoEstadio")
	jogador.invulneravel = 100.0
	jogador.global_position.x = 4140.0
	await esperar(0.1)
	verificar(camera.limit_left == 0 and camera.limit_right == 4344, "camera volta a regiao da cidade")
	Input.action_press("ir_para_direita")
	for i in 90:
		await get_tree().physics_frame
		if viaduto.transicionando:
			break
	verificar(viaduto.transicionando and get_tree().paused and not estadio.transicionando, "viaduto inicia sem acionar o tunel do estadio")
	await esperar(0.31)
	verificar(viaduto.get_node("Tela/Escurecimento").modulate.a > 0.99 and camera.limit_left == 4344 and camera.limit_right == 6516, "escurecimento do viaduto oculta a troca entre 02 e 03")
	verificar(viaduto.get_node("Tela/Escurecimento/Titulo").text.begins_with("PASSAGEM SOB O VIADUTO"), "viaduto tem identificacao propria")
	await esperar(0.55)
	verificar(not get_tree().paused and not viaduto.transicionando, "jogador sai do viaduto com controle restaurado")
	# Continua andando ate o tunel: os dois limites devem funcionar em sequencia.
	for i in 300:
		await get_tree().physics_frame
		if estadio.transicionando:
			break
	verificar(estadio.transicionando and not viaduto.transicionando, "percorrer 03 depois do viaduto aciona somente o tunel seguinte")
	await esperar(0.85)
	Input.action_release("ir_para_direita")
	verificar(camera.limit_left == 6516 and camera.limit_right == 13032, "duas passagens consecutivas preservam camera do campo")
	Input.action_press("ir_para_esquerda")
	for i in 120:
		await get_tree().physics_frame
		if estadio.transicionando:
			break
	await esperar(0.85)
	for i in 300:
		await get_tree().physics_frame
		if viaduto.transicionando:
			break
	verificar(viaduto.transicionando, "caminho de volta atravessa o tunel e depois o viaduto")
	await esperar(0.85)
	Input.action_release("ir_para_esquerda")
	verificar(not get_tree().paused and jogador.global_position.x < 4344 and camera.limit_right == 4344 and camera.limit_left == 0, "volta a cidade sem emenda visivel nem pausa presa")

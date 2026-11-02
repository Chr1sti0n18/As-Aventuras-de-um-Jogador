extends SceneTree

var falhas := 0
var verificacoes := 0
var Global

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("OK TELAS: ", descricao)
	else:
		falhas += 1
		push_error("FALHOU TELAS: " + descricao)

func esperar(tempo: float) -> void:
	await create_timer(tempo, true).timeout

func tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = true
	Input.parse_input_event(evento)
	var soltar := InputEventKey.new()
	soltar.keycode = codigo
	Input.parse_input_event(soltar)

func acionar(nome: String, tela: CanvasLayer = null) -> void:
	var alvo = current_scene if tela == null else tela
	alvo.get_node("Quadro/" + nome).pressed.emit()

func aguardar_troca() -> void:
	for i in 160:
		await process_frame
		if not Global.mudando_cena:
			break
	await esperar(0.04)
	conferir(not Global.mudando_cena, "transicao de tela termina")

func executar() -> void:
	Global = root.get_node("Global")
	Global.definir_som(true)
	Global.definir_invencibilidade(false)
	change_scene_to_file(Global.MENU)
	await esperar(0.12)
	conferir(current_scene.tipo == "inicio" and Global.tela_atual == Global.Tela.INICIO, "projeto abre no menu inicial")
	conferir(current_scene.botoes.size() == 3, "Jogar, Controles e Configuracoes disponiveis")
	tecla(KEY_DOWN)
	await esperar(0.05)
	conferir(root.gui_get_focus_owner().name == "Controles", "setas encontram Controles")
	var musica: float = Global.musica.get_playback_position()
	tecla(KEY_ENTER)
	await esperar(0.05)
	conferir(current_scene.controles_abertos and not current_scene.quadro.visible, "Controles abre painel separado do menu")
	var painel: Control = current_scene.painel_controles
	var centro: Vector2 = painel.position + painel.size * painel.scale * 0.5
	conferir(centro.distance_to(root.get_visible_rect().size * 0.5) < 0.5 and is_equal_approx(painel.scale.x, painel.scale.y), "painel fica centralizado sem distorcer a imagem")
	conferir(Global.musica.get_playback_position() >= musica, "Controles nao reinicia a faixa de abertura")
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	conferir(not current_scene.controles_abertos and current_scene.quadro.visible and root.gui_get_focus_owner().name == "Controles", "Esc volta ao menu e restaura foco de Controles")
	acionar("Controles")
	await esperar(0.05)
	current_scene.painel_controles.get_node("Voltar").pressed.emit()
	await esperar(0.05)
	conferir(not current_scene.controles_abertos, "Voltar fecha painel de controles")
	tecla(KEY_DOWN)
	await esperar(0.05)
	conferir(root.gui_get_focus_owner().name == "Configuracoes", "setas navegam pelos botoes")
	tecla(KEY_ENTER)
	await esperar(0.05)
	conferir(current_scene.config_aberta, "configuracoes abrem no inicio")
	current_scene.botao_som.pressed.emit()
	conferir(not Global.musica_ligada and AudioServer.is_bus_mute(0), "som pode ser desligado")
	current_scene.botao_som.pressed.emit()
	conferir(Global.musica_ligada and not AudioServer.is_bus_mute(0), "som pode ser ligado")
	current_scene.botao_invencibilidade.pressed.emit()
	conferir(Global.invencibilidade, "invencibilidade pode ser ligada")
	var cfg := ConfigFile.new()
	conferir(cfg.load("user://configuracoes.cfg") == OK and cfg.get_value("opcoes", "invencibilidade", false), "configuracoes sao persistidas")
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	conferir(not current_scene.config_aberta, "Esc fecha configuracoes no inicio")
	acionar("Jogar")
	await aguardar_troca()
	conferir(current_scene.name == "Fase" and Global.qtd_vidas == 5 and Global.pontuacao == 0, "Jogar inicia partida nova")
	var jogador = Global.personagem
	conferir(Global.invencibilidade and not jogador.receber_dano(1, 2.5) and Global.qtd_vidas == 5 and jogador.tempo_lento == 0.0, "invencibilidade bloqueia dano e lentidao")
	jogador.tempo_lento = 1.0
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	conferir(paused and is_instance_valid(Global.interface_pausa), "Esc abre pausa")
	var posicao: Vector2 = jogador.global_position
	var lentidao: float = jogador.tempo_lento
	await esperar(0.2)
	conferir(jogador.global_position == posicao and jogador.tempo_lento == lentidao, "pausa congela movimento e efeitos de combate")
	acionar("Configuracoes", Global.interface_pausa)
	Global.interface_pausa.botao_invencibilidade.pressed.emit()
	conferir(not Global.invencibilidade and paused, "configuracoes funcionam durante a pausa")
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	conferir(paused and not Global.interface_pausa.config_aberta, "Esc nas configuracoes volta a pausa")
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	conferir(not paused and not is_instance_valid(Global.interface_pausa), "Esc continua a partida")
	jogador.tempo_lento = 0.0
	jogador.invulneravel = 0.0
	conferir(jogador.receber_dano(1, 2.5) and Global.qtd_vidas == 4 and jogador.tempo_lento > 0.0, "desativar invencibilidade restaura dano e lentidao")
	Global.pontuacao = 500
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	acionar("Reiniciar", Global.interface_pausa)
	await aguardar_troca()
	conferir(Global.qtd_vidas == 5 and Global.pontuacao == 0 and not paused and not Global.invencibilidade, "Reiniciar zera partida e mantem preferencias")
	tecla(KEY_ESCAPE)
	await esperar(0.05)
	acionar("Sair", Global.interface_pausa)
	await aguardar_troca()
	conferir(current_scene.tipo == "inicio" and not paused and not is_instance_valid(Global.personagem), "Sair da pausa retorna ao menu")
	acionar("Jogar")
	await aguardar_troca()
	Global.qtd_vidas = 1
	Global.personagem.invulneravel = 0.0
	Global.personagem.receber_dano(1)
	await esperar(0.05)
	await aguardar_troca()
	conferir(current_scene.tipo == "gameover" and Global.qtd_vidas == 0, "fim das vidas abre arte de Game Over")
	acionar("TentarNovamente")
	await aguardar_troca()
	conferir(current_scene.name == "Fase" and Global.qtd_vidas == 5 and Global.pontuacao == 0, "Tentar novamente inicia partida limpa")
	jogador = Global.personagem
	jogador.invulneravel = 100.0
	# A coleta final requer que a fase esteja limpa.
	for inimigo in get_nodes_in_group("inimigos"):
		inimigo.derrotar()
	jogador.global_position = Vector2(12560, 594)
	jogador.velocity = Vector2.ZERO
	await esperar(0.12)
	conferir(not Global.partida_encerrada and current_scene.name == "Fase", "chegar ao final sem tocar a taca nao encerra partida")
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	for i in 150:
		await process_frame
		if Global.partida_encerrada:
			break
	conferir(Global.partida_encerrada, "pulo coleta a taca automaticamente")
	await aguardar_troca()
	conferir(current_scene.tipo == "vitoria" and not paused, "coleta abre imagem de vitoria")
	conferir(current_scene.get_node("Quadro/JogarNovamente") is Button and current_scene.get_node("Quadro/MenuPrincipal") is Button, "vitoria oferece jogar novamente e menu principal")
	acionar("JogarNovamente")
	await aguardar_troca()
	conferir(current_scene.name == "Fase" and Global.qtd_vidas == 5 and Global.pontuacao == 0, "Jogar novamente reinicia a partida")
	Global.ir_para_menu()
	await aguardar_troca()
	Global.definir_som(true)
	Global.definir_invencibilidade(false)
	print("RESULTADO TELAS: ", verificacoes, " verificacoes; ", falhas, " falhas")
	Global.encerrar_jogo(0 if falhas == 0 else 1)

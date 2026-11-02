extends SceneTree

var Global
var verificacoes := 0
var falhas := 0

func _initialize() -> void:
	call_deferred("executar")

func esperar(tempo: float) -> void:
	await create_timer(tempo, true).timeout

func conferir(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("OK AUDIO: ", descricao)
	else:
		falhas += 1
		push_error("FALHOU AUDIO: " + descricao)

func aguardar_troca() -> void:
	while Global.mudando_cena:
		await process_frame
	await esperar(0.08)

func ultimo_efeito() -> AudioStream:
	return Global.canais_audio[(Global.proximo_canal + 5) % 6].stream

func criar_inimigo(tipo: String, x: float) -> CharacterBody2D:
	var arquivos := {
		"juiz": "res://Personagem/inimigo_juiz/cena_inimigo1.tscn",
		"var": "res://Personagem/inimigo_var/cena_var.tscn",
		"goleiro": "res://Personagem/inimigo_goleiro/cena_goleiro.tscn",
	}
	var cena = load(arquivos[tipo]).instantiate()
	cena.position = Vector2(x, 535 if tipo == "var" else 557)
	current_scene.add_child(cena)
	var corpo = cena.get_node("CharacterBody2D")
	corpo.set_physics_process(false)
	return corpo

func executar() -> void:
	Global = root.get_node("Global")
	Global.definir_som(true)
	Global.definir_invencibilidade(false)
	change_scene_to_file(Global.MENU)
	await esperar(0.15)
	conferir(Global.musica.playing and Global.musica.stream == Global.trilhas["trilha_menuprincipal"], "inicio toca somente a faixa de abertura")
	conferir(not Global.musica.stream.loop, "abertura nao repete em loop")
	conferir(not Global.ambiente.playing and not Global.resultado.playing, "inicio nao sobrepoe torcida ou resultado")
	Global.musica.seek(Global.musica.stream.get_length() - 0.08)
	await esperar(0.3)
	conferir(not Global.musica.playing, "fim da abertura deixa o menu em silencio")
	current_scene.abrir_configuracoes()
	current_scene.fechar_configuracoes()
	await esperar(0.05)
	conferir(not Global.musica.playing, "abrir configuracoes nao reinicia a abertura")
	Global.iniciar_partida()
	await aguardar_troca()
	var jogador = Global.personagem
	Global.definir_invencibilidade(true)
	for inimigo in get_nodes_in_group("inimigos"):
		inimigo.set_physics_process(false)
	await esperar(0.1)
	conferir(Global.musica.playing and Global.musica.stream == Global.trilhas["trilha_jogo"], "Jogar inicia a trilha principal")
	conferir(Global.musica.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "trilha principal tem repeticao continua")
	conferir(not Global.ambiente.playing, "trecho externo nao toca torcida")
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	conferir(ultimo_efeito() == Global.efeitos["pulo"], "pulo real toca pulo_jogador")
	await esperar(0.95)
	jogador.set_physics_process(false)
	jogador.acao = jogador.Acao.CHUTE
	jogador.spawnar_bolar()
	conferir(ultimo_efeito() == Global.efeitos["chute"], "chute real usa ataque_jogador")
	jogador.iniciar_carrinho()
	conferir(ultimo_efeito() == Global.efeitos["carrinho"], "carrinho usa seu arquivo exclusivo")
	jogador.encerrar_carrinho()
	Global.definir_invencibilidade(false)
	jogador.invulneravel = 0.0
	jogador.receber_dano(1)
	conferir(ultimo_efeito() == Global.efeitos["dano"], "dano aceito toca dano_jogador")
	var canal_antes: int = Global.proximo_canal
	jogador.receber_dano(1)
	conferir(Global.proximo_canal == canal_antes, "protecao contra dano nao repete o som")
	Global.definir_invencibilidade(true)
	jogador.invulneravel = 0.0
	jogador.receber_dano(1)
	conferir(Global.proximo_canal == canal_antes, "invencibilidade nao emite falso som de dano")
	jogador.global_position = Vector2(500, 594)
	var juiz = criar_inimigo("juiz", 600)
	juiz.atirar_cartao(false)
	conferir(ultimo_efeito() == Global.efeitos["ataque_juiz"], "juiz toca ataque ao lancar o cartao")
	juiz.receber_dano(1)
	conferir(ultimo_efeito() == Global.efeitos["dano_juiz"], "juiz toca seu dano especifico")
	var goleiro = criar_inimigo("goleiro", 850)
	goleiro.espera_inicial = 0.0
	goleiro.set_physics_process(true)
	for i in 100:
		await physics_frame
		if goleiro.estado == goleiro.Estado.MERGULHO:
			break
	goleiro.set_physics_process(false)
	conferir(goleiro.estado == goleiro.Estado.MERGULHO and ultimo_efeito() == Global.efeitos["ataque_goleiro"], "mergulho real do goleiro toca ataque_goleiro")
	goleiro.receber_dano(1)
	conferir(ultimo_efeito() == Global.efeitos["dano_goleiro"], "goleiro toca dano_goleiro ao receber acerto")
	var var_inimigo = criar_inimigo("var", 800)
	var_inimigo.ativo = true
	var_inimigo.quantidade_lasers = 3
	canal_antes = Global.proximo_canal
	var_inimigo.disparar_laser()
	await esperar(0.55)
	conferir(Global.proximo_canal == (canal_antes + 1) % 6, "sequencia real de tres lasers emite um unico som")
	conferir(ultimo_efeito() == Global.efeitos["ataque_var"], "sequencia usa ataque_var")
	var_inimigo.mudar_estado_voo(var_inimigo.EstadoVoo.BRECHA)
	var_inimigo.receber_dano(1, "pisao")
	conferir(ultimo_efeito() == Global.efeitos["dano_var"], "pisada aceita toca dano_var")
	await esperar(0.5)
	for inimigo in [juiz, goleiro]:
		inimigo.get_parent().queue_free()
	# Testa entrada real na regiao, sem chamar diretamente a rotina de som.
	jogador.global_position.x = 7200
	await esperar(0.1)
	conferir(Global.ambiente.playing and Global.no_estadio, "entrar no panorama adiciona torcida")
	conferir(Global.musica.playing and Global.musica.stream == Global.trilhas["trilha_jogo"], "musica principal continua dentro do estadio")
	Global.musica.seek(Global.musica.stream.get_length() - 0.08)
	Global.ambiente.seek(Global.ambiente.stream.get_length() - 0.08)
	await esperar(0.35)
	conferir(Global.musica.playing and Global.musica.get_playback_position() < 1.0, "musica completa reinicia naturalmente em loop")
	conferir(Global.ambiente.playing and Global.ambiente.get_playback_position() < 1.0, "torcida completa reinicia naturalmente em loop")
	Global.tocar_som("ataque_var")
	Global.pausar()
	await esperar(0.06)
	var pos_musica: float = Global.musica.get_playback_position()
	var pos_ambiente: float = Global.ambiente.get_playback_position()
	var canal: AudioStreamPlayer = Global.canais_audio[(Global.proximo_canal + 5) % 6]
	var pos_efeito := canal.get_playback_position()
	await esperar(0.2)
	conferir(Global.musica.stream_paused and Global.ambiente.stream_paused and canal.stream_paused, "pausa congela musica, torcida e efeitos")
	conferir(absf(Global.musica.get_playback_position() - pos_musica) < 0.025 and absf(Global.ambiente.get_playback_position() - pos_ambiente) < 0.025 and absf(canal.get_playback_position() - pos_efeito) < 0.025, "posicoes dos tres audios permanecem congeladas")
	canal_antes = Global.proximo_canal
	Global.interface_pausa.get_node("Quadro/Configuracoes").pressed.emit()
	Global.interface_pausa.botao_som.pressed.emit()
	conferir(AudioServer.is_bus_mute(0), "Som desligado silencia o barramento geral")
	Global.interface_pausa.botao_som.pressed.emit()
	conferir(not AudioServer.is_bus_mute(0) and Global.proximo_canal == canal_antes and Global.audio_botoes.playing and not Global.audio_botoes.stream_paused and Global.musica.stream_paused and Global.ambiente.stream_paused and canal.stream_paused, "botoes da pausa tocam sem retomar musica, torcida ou efeitos da partida")
	Global.interface_pausa.fechar_configuracoes()
	Global.continuar()
	await esperar(0.13)
	conferir(Global.musica.get_playback_position() > pos_musica and Global.ambiente.get_playback_position() > pos_ambiente and canal.get_playback_position() > pos_efeito, "continuar retoma os audios do mesmo ponto")
	Global.definir_som(false)
	canal_antes = Global.proximo_canal
	Global.tocar_som("chute")
	conferir(Global.proximo_canal == canal_antes and AudioServer.is_bus_mute(0), "som desligado tambem bloqueia novos efeitos")
	Global.definir_som(true)
	pos_musica = Global.musica.get_playback_position()
	jogador.global_position.x = 6200
	await esperar(0.1)
	conferir(not Global.ambiente.playing and Global.musica.get_playback_position() > pos_musica, "sair do estadio remove torcida sem reiniciar a musica")
	Global.finalizar_partida(true)
	await aguardar_troca()
	conferir(Global.resultado.playing and Global.resultado.stream == Global.efeitos["vitoria"], "vitoria toca a faixa fornecida")
	conferir(not Global.musica.playing and not Global.ambiente.playing, "vitoria encerra as trilhas da partida")
	Global.resultado.seek(Global.resultado.stream.get_length() - 0.08)
	await esperar(0.3)
	conferir(not Global.resultado.playing and not Global.musica.playing, "vitoria toca uma unica vez")
	Global.iniciar_partida()
	await aguardar_troca()
	conferir(Global.musica.playing and not Global.resultado.playing and not Global.ambiente.playing, "reiniciar limpa resultado e torcida")
	Global.finalizar_partida(false)
	await aguardar_troca()
	conferir(Global.resultado.playing and Global.resultado.stream == Global.efeitos["derrota"], "Game Over toca gameover.wav")
	conferir(not Global.musica.playing and not Global.ambiente.playing, "Game Over encerra as trilhas da partida")
	Global.ir_para_menu()
	await aguardar_troca()
	conferir(Global.musica.playing and Global.musica.stream == Global.trilhas["trilha_menuprincipal"] and not Global.resultado.playing, "retornar ao menu toca novamente apenas a abertura")
	Global.definir_invencibilidade(false)
	Global.definir_som(true)
	print("RESULTADO AUDIO: ", verificacoes, " verificacoes; ", falhas, " falhas")
	Global.encerrar_jogo(0 if falhas == 0 else 1)

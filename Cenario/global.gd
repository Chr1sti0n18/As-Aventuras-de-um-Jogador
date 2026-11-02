extends Node

enum Tela { INICIO, PARTIDA, GAMEOVER, VITORIA }
const FASE = "res://Cenario/cena_fase.tscn"
const MENU = "res://Cenario/telas/inicio.tscn"
const DERROTA = "res://Cenario/gameover/cena_game_over.tscn"
const VITORIA = "res://Cenario/telas/vitoria.tscn"
const VIDAS_INICIAIS := 5
var qtd_vidas := VIDAS_INICIAIS
var fase_atual := 1
var pontuacao := 0
var valor_dano := 1
var musica_ligada := true
var invencibilidade := false
var personagem: Node2D
var tela_atual := Tela.INICIO
var partida_encerrada := false
var mudando_cena := false
var interface_pausa: CanvasLayer
var efeitos: Dictionary = {}
var canais_audio: Array[AudioStreamPlayer] = []
var proximo_canal := 0
var trilhas: Dictionary = {}
var musica: AudioStreamPlayer
var ambiente: AudioStreamPlayer
var resultado: AudioStreamPlayer
var audio_botoes: AudioStreamPlayer
var no_estadio := false
var geracao_audio := 0
var encerrando := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	get_window().close_requested.connect(encerrar_jogo)
	resetar_variaveis()
	carregar_configuracoes()
	for nome in ["clique", "chute", "pulo", "dano", "acerto", "coleta", "vitoria", "derrota"]:
		efeitos[nome] = load("res://Audio/" + nome + ".wav")
	var arquivos := {
		"clique": "apertar_botao.mp3",
		"chute": "ataque_jogador.mp3", "carrinho": "jogador_carrinho.wav",
		"pulo": "pulo_jogador.wav", "dano": "dano_jogador.wav",
		"ataque_juiz": "ataque_juiz.mp3", "dano_juiz": "dano_juiz.mp3",
		"ataque_var": "ataque_var.mp3", "dano_var": "dano_var.wav",
		"ataque_goleiro": "ataque_goleiro.wav", "dano_goleiro": "dano_goleiro.mp3",
		"vitoria": "vitoria.wav", "derrota": "gameover.wav",
	}
	for nome in arquivos:
		efeitos[nome] = load("res://Audio/Importados/" + arquivos[nome])
	for nome in ["trilha_jogo.wav", "trilha_estadio.wav", "trilha_menuprincipal.mp3"]:
		# Duplicar o recurso permite ajustar repeticao sem alterar o arquivo original.
		var faixa: AudioStream = load("res://Audio/Importados/" + nome)
		if faixa is AudioStreamWAV:
			faixa = faixa.duplicate()
			faixa.loop_mode = AudioStreamWAV.LOOP_FORWARD
			faixa.loop_begin = 0
			faixa.loop_end = roundi(faixa.get_length() * faixa.mix_rate)
		elif faixa is AudioStreamMP3:
			faixa.loop = false
		trilhas[nome.get_basename()] = faixa
	for i in 6:
		canais_audio.append(criar_canal("Efeito" + str(i), -7.0))
	musica = criar_canal("Musica", -14.0)
	# A gravacao da torcida ja tem nivel bem mais baixo que a musica.
	ambiente = criar_canal("AmbienteEstadio", 0.0)
	resultado = criar_canal("Resultado", -7.0)
	audio_botoes = criar_canal("Botoes", -7.0)
	# O clique termina durante o fade, que pausa a fisica da partida.
	audio_botoes.process_mode = Node.PROCESS_MODE_ALWAYS

func criar_canal(nome: String, volume: float) -> AudioStreamPlayer:
	var canal := AudioStreamPlayer.new()
	canal.name = nome
	# Global continua processando para o menu; seus sons acompanham a pausa da arvore.
	canal.process_mode = Node.PROCESS_MODE_PAUSABLE
	canal.volume_db = volume
	add_child(canal)
	return canal

func parar_audio() -> void:
	geracao_audio += 1
	for canal in canais_audio + [musica, ambiente, resultado, audio_botoes]:
		canal.stop()
	no_estadio = false

func iniciar_faixa(canal: AudioStreamPlayer, faixa: AudioStream) -> void:
	if encerrando:
		return
	var geracao := geracao_audio
	canal.stream = faixa
	# As telas sao criadas no meio do fade, com a arvore ainda pausada.
	# Iniciar depois da retomada evita criar uma reproducao ja suspensa.
	while get_tree().paused:
		await get_tree().process_frame
	if geracao == geracao_audio and canal.stream == faixa:
		canal.play()

func encerrar_jogo(codigo: int = 0) -> void:
	if encerrando:
		return
	encerrando = true
	get_tree().paused = true
	parar_audio()
	# O servidor de audio libera os decodificadores na proxima mistura.
	await get_tree().create_timer(0.1, true).timeout
	get_tree().quit(codigo)

func _exit_tree() -> void:
	for canal in canais_audio + [musica, ambiente, resultado, audio_botoes]:
		if is_instance_valid(canal):
			canal.stop()
			canal.stream = null
	canais_audio.clear()
	efeitos.clear()
	trilhas.clear()

func registrar_tela(tipo: String) -> void:
	parar_audio()
	match tipo:
		"inicio":
			tela_atual = Tela.INICIO
			musica.volume_db = -10.0
			iniciar_faixa(musica, trilhas["trilha_menuprincipal"])
		"vitoria", "gameover":
			tela_atual = Tela.VITORIA if tipo == "vitoria" else Tela.GAMEOVER
			iniciar_faixa(resultado, efeitos["vitoria" if tipo == "vitoria" else "derrota"])

func definir_estadio(dentro: bool) -> void:
	if dentro == no_estadio or tela_atual != Tela.PARTIDA or partida_encerrada:
		return
	no_estadio = dentro
	if dentro:
		iniciar_faixa(ambiente, trilhas["trilha_estadio"])
	else:
		ambiente.stop()

func resetar_variaveis() -> void:
	qtd_vidas = VIDAS_INICIAIS
	fase_atual = 1
	pontuacao = 0
	valor_dano = 1
	partida_encerrada = false

func registrar_fase() -> void:
	tela_atual = Tela.PARTIDA
	partida_encerrada = false
	parar_audio()
	musica.volume_db = -14.0
	iniciar_faixa(musica, trilhas["trilha_jogo"])

func tocar_som(nome: String) -> void:
	if encerrando or not musica_ligada or not efeitos.has(nome) or canais_audio.is_empty():
		return
	if nome == "clique":
		audio_botoes.stream = efeitos[nome]
		audio_botoes.play()
		return
	if get_tree().paused:
		return
	var canal := canais_audio[proximo_canal]
	proximo_canal = (proximo_canal + 1) % canais_audio.size()
	var ajuste_db := {"ataque_juiz": 6.0, "dano_juiz": 6.0, "ataque_goleiro": 6.0, "dano_goleiro": 6.0, "dano": 4.0, "carrinho": -3.0}
	canal.volume_db = -7.0 + float(ajuste_db.get(nome, 0.0))
	canal.stream = efeitos[nome]
	canal.play()

func definir_som(ligado: bool) -> void:
	musica_ligada = ligado
	AudioServer.set_bus_mute(0, not ligado)
	salvar_configuracoes()

func definir_invencibilidade(ligada: bool) -> void:
	invencibilidade = ligada
	salvar_configuracoes()

func salvar_configuracoes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("opcoes", "som", musica_ligada)
	cfg.set_value("opcoes", "invencibilidade", invencibilidade)
	cfg.save("user://configuracoes.cfg")

func carregar_configuracoes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://configuracoes.cfg") == OK:
		musica_ligada = bool(cfg.get_value("opcoes", "som", true))
		invencibilidade = bool(cfg.get_value("opcoes", "invencibilidade", false))
	AudioServer.set_bus_mute(0, not musica_ligada)

func iniciar_partida() -> void:
	if mudando_cena:
		return
	resetar_variaveis()
	mudar_cena(FASE)

func ir_para_menu() -> void:
	if mudando_cena:
		return
	mudar_cena(MENU)

func finalizar_partida(venceu: bool) -> void:
	if partida_encerrada or mudando_cena or tela_atual != Tela.PARTIDA:
		return
	partida_encerrada = true
	parar_audio()
	mudar_cena(VITORIA if venceu else DERROTA)

func pausar() -> void:
	if tela_atual != Tela.PARTIDA or mudando_cena or partida_encerrada or get_tree().paused:
		return
	interface_pausa = load("res://Cenario/telas/pausa.tscn").instantiate()
	get_tree().root.add_child(interface_pausa)
	get_tree().paused = true

func continuar() -> void:
	if mudando_cena:
		return
	liberar_pausa()
	get_tree().paused = false

func liberar_pausa() -> void:
	if is_instance_valid(interface_pausa):
		interface_pausa.queue_free()
	interface_pausa = null

func mudar_cena(caminho: String) -> void:
	if mudando_cena:
		return
	mudando_cena = true
	get_tree().paused = true
	var camada := CanvasLayer.new()
	camada.layer = 200
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	var cobertura := ColorRect.new()
	camada.add_child(cobertura)
	cobertura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cobertura.color = Color(0.015, 0.025, 0.04)
	cobertura.modulate.a = 0.0
	var fechar := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fechar.tween_property(cobertura, "modulate:a", 1.0, 0.22)
	await fechar.finished
	liberar_pausa()
	personagem = null
	var resultado := get_tree().change_scene_to_file(caminho)
	if resultado != OK:
		push_error("Nao foi possivel abrir: " + caminho)
	await get_tree().process_frame
	get_tree().paused = false
	var abrir := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	abrir.tween_property(cobertura, "modulate:a", 0.0, 0.22)
	await abrir.finished
	camada.queue_free()
	mudando_cena = false

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11 or event.physical_keycode == KEY_F11:
		var janela := get_window()
		janela.mode = Window.MODE_MAXIMIZED if janela.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and tela_atual == Tela.PARTIDA and not mudando_cena:
		if is_instance_valid(interface_pausa):
			interface_pausa.ao_escape()
		else:
			pausar()
		get_viewport().set_input_as_handled()

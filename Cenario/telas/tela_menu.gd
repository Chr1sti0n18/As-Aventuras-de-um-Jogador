extends CanvasLayer

@export_enum("inicio", "pausa", "gameover", "vitoria") var tipo: String = "inicio"
const TAMANHO := Vector2(1672, 941)
var quadro: Control
var botoes: Array[Button] = []
var modal: Control
var config_aberta := false
var botao_som: Button
var botao_invencibilidade: Button
var controles_abertos := false
var tela_controles: Control
var painel_controles: Control
const TAMANHO_CONTROLES := Vector2(1600, 1080)
# Fracao maxima da janela ocupada pelo painel; o restante fica como fundo verde.
const OCUPACAO_CONTROLES := 0.72

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tipo != "pausa":
		Global.registrar_tela(tipo)
	var margem := ColorRect.new()
	margem.color = Color(0.015, 0.035, 0.055)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quadro = Control.new()
	quadro.name = "Quadro"
	quadro.size = TAMANHO
	add_child(quadro)
	var imagem := TextureRect.new()
	imagem.name = "Arte"
	imagem.size = TAMANHO
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_SCALE
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quadro.add_child(imagem)
	var arquivos := {"inicio": "Menu_Principal.png", "pausa": "Pause.png", "gameover": "Gameover.png", "vitoria": "Vitoria.png"}
	imagem.texture = load("res://Cenario/telas/assets/" + arquivos[tipo])
	match tipo:
		"inicio":
			Global.tela_atual = Global.Tela.INICIO
			adicionar_botao("Jogar", Rect2(578, 538, 520, 91), Global.iniciar_partida)
			adicionar_botao("Controles", Rect2(578, 640, 520, 91), abrir_controles)
			adicionar_botao("Configuracoes", Rect2(578, 741, 520, 91), abrir_configuracoes)
		"pausa":
			adicionar_botao("Continuar", Rect2(584, 395, 504, 85), Global.continuar)
			adicionar_botao("Reiniciar", Rect2(584, 491, 504, 89), Global.iniciar_partida)
			adicionar_botao("Configuracoes", Rect2(584, 589, 504, 89), abrir_configuracoes)
			adicionar_botao("Sair", Rect2(584, 688, 504, 89), Global.ir_para_menu)
		"gameover":
			Global.tela_atual = Global.Tela.GAMEOVER
			adicionar_botao("TentarNovamente", Rect2(530, 659, 610, 96), Global.iniciar_partida)
			adicionar_botao("MenuPrincipal", Rect2(530, 762, 610, 96), Global.ir_para_menu)
		"vitoria":
			Global.tela_atual = Global.Tela.VITORIA
			var pontos := criar_label("PONTUAÇÃO: " + str(Global.pontuacao), Rect2(500, 744, 672, 40), 25)
			quadro.add_child(pontos)
			adicionar_botao("JogarNovamente", Rect2(290, 808, 510, 82), Global.iniciar_partida, "JOGAR NOVAMENTE")
			adicionar_botao("MenuPrincipal", Rect2(870, 808, 510, 82), Global.ir_para_menu, "MENU PRINCIPAL", true)
	organizar_foco(botoes)
	get_viewport().size_changed.connect(ajustar_layout)
	ajustar_layout()

func ajustar_layout() -> void:
	var disponivel := get_viewport().get_visible_rect().size
	# Arte e botoes usam a mesma transformacao e preenchem toda a area do jogo.
	quadro.scale = disponivel / TAMANHO
	quadro.position = Vector2.ZERO
	if controles_abertos:
		tela_controles.size = disponivel
		# Nunca amplia alem do tamanho original da imagem.
		var fator := minf(1.0, minf(disponivel.x * OCUPACAO_CONTROLES / TAMANHO_CONTROLES.x, disponivel.y * OCUPACAO_CONTROLES / TAMANHO_CONTROLES.y))
		painel_controles.scale = Vector2.ONE * fator
		painel_controles.position = (disponivel - TAMANHO_CONTROLES * fator) * 0.5

func abrir_controles() -> void:
	if controles_abertos:
		return
	controles_abertos = true
	quadro.hide()
	tela_controles = Control.new()
	tela_controles.name = "TelaControles"
	add_child(tela_controles)
	var fundo := ColorRect.new()
	fundo.color = Color("#036e28")
	tela_controles.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel_controles = Control.new()
	painel_controles.name = "Painel"
	painel_controles.size = TAMANHO_CONTROLES
	tela_controles.add_child(painel_controles)
	var imagem := TextureRect.new()
	imagem.name = "Imagem"
	imagem.texture = load("res://Cenario/telas/assets/painel_controles.png")
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagem.size = TAMANHO_CONTROLES
	painel_controles.add_child(imagem)
	var voltar := adicionar_botao("Voltar", Rect2(600, 912, 400, 78), fechar_controles, "VOLTAR", false, painel_controles)
	organizar_foco([voltar])
	ajustar_layout()

func fechar_controles() -> void:
	if not controles_abertos:
		return
	tela_controles.queue_free()
	tela_controles = null
	painel_controles = null
	controles_abertos = false
	quadro.show()
	quadro.get_node("Controles").call_deferred("grab_focus")

func estilo(cor: Color, borda: Color, largura: int = 3) -> StyleBoxFlat:
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = cor
	caixa.border_color = borda
	caixa.set_border_width_all(largura)
	caixa.set_corner_radius_all(5)
	return caixa

func adicionar_botao(nome: String, retangulo: Rect2, acao: Callable, rotulo: String = "", azul: bool = false, pai: Control = null) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.position = retangulo.position
	botao.size = retangulo.size
	botao.text = rotulo
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.focus_mode = Control.FOCUS_ALL
	botao.add_theme_font_size_override("font_size", 27)
	var fonte := SystemFont.new()
	fonte.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono"])
	fonte.font_weight = 700
	botao.add_theme_font_override("font", fonte)
	if rotulo.is_empty():
		botao.add_theme_stylebox_override("normal", estilo(Color.TRANSPARENT, Color.TRANSPARENT, 0))
		botao.add_theme_stylebox_override("disabled", estilo(Color.TRANSPARENT, Color.TRANSPARENT, 0))
		botao.add_theme_stylebox_override("hover", estilo(Color(1, 0.85, 0.2, 0.10), Color(1, 0.95, 0.6), 3))
		botao.add_theme_stylebox_override("pressed", estilo(Color(0, 0, 0, 0.15), Color(1, 0.8, 0.15), 3))
	else:
		var base := Color("#0751ba") if azul else Color("#f7bc13")
		botao.add_theme_stylebox_override("normal", estilo(base, Color("#fff0a0")))
		botao.add_theme_stylebox_override("hover", estilo(base.lightened(0.15), Color.WHITE, 4))
		botao.add_theme_stylebox_override("pressed", estilo(base.darkened(0.18), Color("#ffdb67"), 4))
		botao.add_theme_color_override("font_color", Color.WHITE if azul else Color("#07221e"))
		botao.add_theme_color_override("font_hover_color", Color.WHITE if azul else Color("#07221e"))
		botao.add_theme_color_override("font_pressed_color", Color.WHITE if azul else Color("#07221e"))
		botao.add_theme_color_override("font_focus_color", Color.WHITE if azul else Color("#07221e"))
	botao.add_theme_stylebox_override("focus", estilo(Color.TRANSPARENT, Color(1, 0.97, 0.65), 4))
	botao.pressed.connect(executar_acao.bind(acao))
	(pai if pai != null else quadro).add_child(botao)
	if pai == null:
		botoes.append(botao)
	return botao

func executar_acao(acao: Callable) -> void:
	if Global.mudando_cena:
		return
	Global.tocar_som("clique")
	acao.call()

func organizar_foco(lista: Array[Button]) -> void:
	for i in lista.size():
		var anterior := lista[(i - 1 + lista.size()) % lista.size()].get_path()
		var proximo := lista[(i + 1) % lista.size()].get_path()
		lista[i].focus_neighbor_top = anterior
		lista[i].focus_neighbor_left = anterior
		lista[i].focus_neighbor_bottom = proximo
		lista[i].focus_neighbor_right = proximo
		lista[i].focus_next = proximo
		lista[i].focus_previous = anterior
	if not lista.is_empty():
		lista[0].call_deferred("grab_focus")

func criar_label(texto: String, retangulo: Rect2, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.position = retangulo.position
	rotulo.size = retangulo.size
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", Color("#fff0ac"))
	rotulo.add_theme_color_override("font_outline_color", Color("#05291e"))
	rotulo.add_theme_constant_override("outline_size", 5)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo

func abrir_configuracoes() -> void:
	if config_aberta:
		return
	config_aberta = true
	for botao in botoes:
		botao.disabled = true
	modal = Control.new()
	modal.name = "Configuracoes"
	modal.size = TAMANHO
	quadro.add_child(modal)
	var sombra := ColorRect.new()
	sombra.size = TAMANHO
	sombra.color = Color(0, 0.02, 0.05, 0.78)
	modal.add_child(sombra)
	var painel := Panel.new()
	painel.position = Vector2(500, 210)
	painel.size = Vector2(672, 520)
	painel.add_theme_stylebox_override("panel", estilo(Color("#06352d"), Color("#f9d64b"), 5))
	modal.add_child(painel)
	modal.add_child(criar_label("CONFIGURAÇÕES", Rect2(520, 245, 632, 55), 36))
	botao_som = adicionar_botao("Som", Rect2(560, 335, 552, 76), alternar_som, "SOM", true, modal)
	botao_invencibilidade = adicionar_botao("Invencibilidade", Rect2(560, 435, 552, 76), alternar_invencibilidade, "INVENCIBILIDADE", true, modal)
	modal.add_child(criar_label("Invencibilidade evita dano e lentidão.", Rect2(525, 530, 622, 45), 21))
	var voltar := adicionar_botao("Voltar", Rect2(660, 610, 352, 72), fechar_configuracoes, "VOLTAR", false, modal)
	atualizar_opcoes()
	organizar_foco([botao_som, botao_invencibilidade, voltar])

func atualizar_opcoes() -> void:
	botao_som.text = "SOM: " + ("LIGADO" if Global.musica_ligada else "DESLIGADO")
	botao_invencibilidade.text = "INVENCIBILIDADE: " + ("LIGADA" if Global.invencibilidade else "DESLIGADA")

func alternar_som() -> void:
	Global.definir_som(not Global.musica_ligada)
	atualizar_opcoes()
	Global.tocar_som("clique")

func alternar_invencibilidade() -> void:
	Global.definir_invencibilidade(not Global.invencibilidade)
	atualizar_opcoes()

func fechar_configuracoes() -> void:
	if not config_aberta:
		return
	modal.queue_free()
	modal = null
	config_aberta = false
	for botao in botoes:
		botao.disabled = false
	for botao in botoes:
		if botao.name == "Configuracoes":
			botao.call_deferred("grab_focus")

func ao_escape() -> void:
	if controles_abertos:
		fechar_controles()
	elif config_aberta:
		fechar_configuracoes()
	elif tipo == "pausa":
		Global.continuar()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and (config_aberta or controles_abertos):
		ao_escape()
		get_viewport().set_input_as_handled()

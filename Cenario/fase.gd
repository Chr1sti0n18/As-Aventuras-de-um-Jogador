extends Node2D

const BARREIRA = preload("res://Cenario/barreira_area.gd")
var limites_areas: Array[float] = []
var inimigos_areas: Array = []
var barreiras: Array[Node2D] = []
var progresso: Label

func _ready() -> void:
	Global.registrar_fase()
	for imagem in $Cenarios.get_children():
		limites_areas.append(imagem.global_position.x)
		inimigos_areas.append([])
	var ultima: Sprite2D = $Cenarios.get_child($Cenarios.get_child_count() - 1)
	limites_areas.append(ultima.global_position.x + ultima.texture.get_width() * ultima.scale.x)
	for inimigo in $Inimigos.get_children():
		registrar_inimigo(inimigo)
	$Inimigos.child_entered_tree.connect(func(no: Node): registrar_inimigo.call_deferred(no))
	var jogador: CharacterBody2D = Global.personagem
	jogador.set_collision_mask_value(5, true)
	for i in range(1, limites_areas.size() - 1):
		var barreira = BARREIRA.new()
		barreira.name = "BarreiraArea" + str(i)
		barreira.position.x = limites_areas[i]
		barreira.lado_positivo = jogador.global_position.x >= limites_areas[i]
		add_child(barreira)
		barreiras.append(barreira)
	progresso = Label.new()
	progresso.name = "ProgressoArea"
	$Interface.add_child(progresso)
	progresso.anchor_left = 0.5
	progresso.anchor_right = 0.5
	progresso.offset_left = -250
	progresso.offset_right = 250
	progresso.offset_top = 25
	progresso.offset_bottom = 60
	progresso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progresso.add_theme_font_size_override("font_size", 20)
	progresso.add_theme_color_override("font_color", Color("#ffe563"))
	progresso.add_theme_color_override("font_outline_color", Color("#092c22"))
	progresso.add_theme_constant_override("outline_size", 5)
	atualizar_ambiente()
	atualizar_barreiras()

func _physics_process(_delta: float) -> void:
	atualizar_ambiente()
	atualizar_barreiras()

func area_em_x(x: float) -> int:
	for i in range(inimigos_areas.size() - 1, -1, -1):
		if x >= limites_areas[i]:
			return i
	return 0

func registrar_inimigo(cena: Node) -> void:
	if not is_instance_valid(cena):
		return
	var inimigo = cena.get_node_or_null("CharacterBody2D")
	if inimigo == null or not inimigo.has_method("definir_area") or inimigo.area_origem >= 0:
		return
	var indice := area_em_x(inimigo.global_position.x)
	inimigo.definir_area(indice, limites_areas[indice], limites_areas[indice + 1])
	inimigos_areas[indice].append(inimigo)

func inimigos_restantes(indice: int) -> int:
	var restantes := 0
	for inimigo in inimigos_areas[indice]:
		if is_instance_valid(inimigo) and not inimigo.derrotado:
			restantes += 1
	return restantes

func restantes_para_passagem(indice: int, avancando: bool) -> int:
	if not avancando:
		return inimigos_restantes(indice)
	var restantes := 0
	for i in range(indice):
		restantes += inimigos_restantes(i)
	return restantes

func pode_atravessar(fronteira: float, avancando: bool) -> bool:
	for i in range(1, limites_areas.size() - 1):
		if is_equal_approx(fronteira, limites_areas[i]):
			return restantes_para_passagem(i, avancando) == 0
	return true

func pode_coletar_taca() -> bool:
	for i in inimigos_areas.size():
		if inimigos_restantes(i) > 0:
			return false
	return true

func atualizar_barreiras() -> void:
	if not is_instance_valid(Global.personagem):
		return
	var x: float = Global.personagem.global_position.x
	for i in barreiras.size():
		var barreira = barreiras[i]
		# Fecha atras apenas depois que o corpo inteiro passou, sem prende-lo na parede.
		if x > barreira.position.x + 64.0:
			barreira.lado_positivo = true
		elif x < barreira.position.x - 64.0:
			barreira.lado_positivo = false
		barreira.atualizar(restantes_para_passagem(i + 1, not barreira.lado_positivo), x)
	var indice := area_em_x(x)
	progresso.text = "ÁREA %d/%d · INIMIGOS: %d" % [indice + 1, inimigos_areas.size(), inimigos_restantes(indice)]

func atualizar_ambiente() -> void:
	if is_instance_valid(Global.personagem):
		Global.definir_estadio(Global.personagem.global_position.x >= $Cenarios/EstadioCompleto.global_position.x)

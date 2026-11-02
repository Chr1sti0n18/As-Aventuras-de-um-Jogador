extends Node2D

var falhas := 0
var verificacoes := 0
var fase: Node2D
var jogador: CharacterBody2D

func verificar(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("OK: ", descricao)
	else:
		falhas += 1
		push_error("FALHOU: " + descricao)

func esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout

func criar(tipo: String, x: float) -> CharacterBody2D:
	var caminhos := {
		"juiz": "res://Personagem/inimigo_juiz/cena_inimigo1.tscn",
		"goleiro": "res://Personagem/inimigo_goleiro/cena_goleiro.tscn",
		"var": "res://Personagem/inimigo_var/cena_var.tscn",
	}
	var alturas := {"juiz": 557.0, "goleiro": 559.0, "var": 535.0}
	var cena = load(caminhos[tipo]).instantiate()
	cena.position = Vector2(x, alturas[tipo])
	fase.get_node("Inimigos").add_child(cena)
	return cena.get_node("CharacterBody2D")

func limpar() -> void:
	Input.action_release("chutar")
	Input.action_release("carrinho")
	Input.action_release("pular")
	Input.action_release("ir_para_direita")
	for no in fase.get_node("Inimigos").get_children():
		no.queue_free()
	for no in get_tree().get_nodes_in_group("cartoes"):
		no.get_parent().queue_free()
	for no in get_children():
		if no.name.begins_with("Bola"):
			no.queue_free()
	jogador.global_position = Vector2(500.0, 594.0)
	jogador.velocity = Vector2.ZERO
	jogador.acao = jogador.Acao.LIVRE
	jogador.tempo_lento = 0.0
	jogador.invulneravel = 0.0
	jogador.intervalo_carrinho = 0.0
	jogador.set_physics_process(true)
	jogador.get_node("CollisionShape2D").set_deferred("disabled", false)
	jogador.get_node("ColisaoCarrinho").set_deferred("disabled", true)
	Global.qtd_vidas = 1000
	await esperar(0.08)

func _ready() -> void:
	Global.definir_invencibilidade(false)
	fase = load("res://Cenario/cena_fase.tscn").instantiate()
	add_child(fase)
	jogador = Global.personagem
	Global.qtd_vidas = 1000
	await esperar(0.25)
	verificar(fase.get_node("Cenarios").get_child_count() == 4, "tres cenarios externos e um panorama continuo no estadio")
	verificar(fase.get_node("Inimigos").get_child_count() == 13, "treze encontros no percurso menor")
	var anterior := -1.0
	for imagem in fase.get_node("Cenarios").get_children():
		var largura_esperada := 6516.0 if imagem.name == "EstadioCompleto" else 2172.0
		verificar(imagem.position.x > anterior and is_equal_approx(imagem.texture.get_width() * imagem.scale.x, largura_esperada), "ordem e largura de " + imagem.name)
		anterior = imagem.position.x
	var panorama = fase.get_node("Cenarios/EstadioCompleto")
	verificar(is_equal_approx(panorama.scale.x, panorama.scale.y), "panorama preserva a proporcao original")
	verificar(is_equal_approx(panorama.position.x + panorama.texture.get_width() * panorama.scale.x, 13032.0), "panorama cobre o estadio ate o limite final")
	verificar(jogador.is_on_floor(), "jogador pousa no chao")
	verificar(jogador.get_node("Sprite2D").scale.y > 0.52 and jogador.get_node("CollisionShape2D").shape.size.y == 75.0, "jogador maior com colisao ajustada")
	verificar(jogador.get_node("Camera2D").limit_right == 4344, "camera externa esconde a emenda do viaduto")
	verificar(fase.get_node("Interface/HUD").get_script() != null, "HUD ativo")
	await limpar()
	await testar_cartoes()
	await limpar()
	await testar_bola()
	await limpar()
	await testar_carrinho()
	await limpar()
	await testar_var()
	await limpar()
	await testar_ciclo_var()
	await limpar()
	await testar_goleiro()
	await limpar()
	await testar_laser()
	await limpar()
	await testar_limites()
	print("RESULTADO: ", verificacoes, " verificacoes; ", falhas, " falhas")
	Global.encerrar_jogo(0 if falhas == 0 else 1)

func testar_cartoes() -> void:
	var juiz = criar("juiz", 300.0)
	juiz.get_node("AnimationPlayer").speed_scale = 0.0
	juiz.atirar_cartao(false)
	var amarelo = get_tree().get_nodes_in_group("cartoes").back()
	verificar(amarelo.direcao == 1 and not amarelo.get_node("Sprite2D").flip_h, "amarelo sai e olha para direita")
	var x: float = amarelo.global_position.x
	await esperar(0.04)
	verificar(amarelo.global_position.x > x, "amarelo avanca na direcao configurada")
	await esperar(0.35)
	verificar(Global.qtd_vidas == 999 and jogador.tempo_lento == 0.0, "amarelo causa um dano sem lentidao")
	await esperar(0.5)
	jogador.global_position.x = 100.0
	juiz.atirar_cartao(true)
	var vermelho = get_tree().get_nodes_in_group("cartoes").back()
	verificar(vermelho.direcao == -1 and vermelho.get_node("Sprite2D").flip_h, "vermelho sai e olha para esquerda")
	verificar(vermelho.get_node("AnimationPlayer").current_animation == "vermelho", "vermelho usa os frames vermelhos")
	await esperar(0.4)
	verificar(Global.qtd_vidas == 998 and jogador.tempo_lento > 2.0, "vermelho causa um dano e lentidao")
	Input.action_press("ir_para_direita")
	await esperar(0.1)
	verificar(is_equal_approx(jogador.velocity.x, 275.0), "lentidao reduz velocidade a 55 por cento")
	jogador.tempo_lento = 0.03
	await esperar(0.1)
	verificar(is_equal_approx(jogador.velocity.x, 500.0), "velocidade volta ao normal")
	Input.action_release("ir_para_direita")
	# Testar os eventos reais da animacao, sem chamar o arremesso manualmente.
	await limpar()
	juiz = criar("juiz", 800.0)
	jogador.global_position.x = 500.0
	jogador.invulneravel = 100.0
	var vistos: Dictionary = {}
	var cores: Array[bool] = []
	var instantes: Array[float] = []
	for i in 400:
		await get_tree().physics_frame
		for cartao in get_tree().get_nodes_in_group("cartoes"):
			if not vistos.has(cartao.get_instance_id()):
				vistos[cartao.get_instance_id()] = true
				cores.append(cartao.vermelho)
				instantes.append(float(i) / Engine.physics_ticks_per_second)
		if cores.size() >= 3:
			break
	verificar(cores.size() >= 3 and cores[0] == false and cores[1] == true and cores[2] == false, "animacao alterna amarelo, vermelho, amarelo")
	verificar(instantes.size() >= 3 and absf(instantes[1] - instantes[0] - 1.5) < 0.1 and absf(instantes[2] - instantes[1] - 1.5) < 0.1, "juiz arremessa a cada 1.5 segundo")
	# Interromper depois do amarelo deve retomar a preparacao do vermelho.
	jogador.global_position.x = 2000.0
	await esperar(0.08)
	verificar(juiz.proximo_vermelho, "juiz guarda a proxima cor ao sair de alcance")
	for cartao in get_tree().get_nodes_in_group("cartoes"):
		cartao.get_parent().queue_free()
	await esperar(0.05)
	jogador.global_position.x = 500.0
	var retomou_vermelho := false
	for i in 160:
		await get_tree().physics_frame
		for cartao in get_tree().get_nodes_in_group("cartoes"):
			retomou_vermelho = cartao.vermelho
		if not get_tree().get_nodes_in_group("cartoes").is_empty():
			break
	verificar(retomou_vermelho, "juiz retoma com vermelho apos interrupcao")

func testar_bola() -> void:
	var juiz = criar("juiz", 760.0)
	juiz.get_node("AnimationPlayer").speed_scale = 0.0
	Input.action_press("chutar")
	var piscou := false
	for i in 80:
		await get_tree().physics_frame
		if juiz.get_node("Sprite2D").modulate.g < 0.9:
			piscou = true
		if juiz.vida == 1:
			break
	Input.action_release("chutar")
	await esperar(0.05)
	verificar(juiz.vida == 1, "bola disparada pelo chute causa dano")
	verificar(piscou or juiz.get_node("Sprite2D").modulate.g < 0.9, "inimigo pisca vermelho")
	verificar(not juiz.receber_dano(1, "bola"), "protecao evita dano duplicado no mesmo instante")
	await esperar(0.5)
	juiz.get_node("AnimationPlayer").speed_scale = 0.0
	await esperar(0.03)
	juiz.receber_dano(1, "bola")
	verificar(juiz.derrotado and juiz.vida == 0, "juiz derrotado ao esgotar vida")
	var casca = juiz.get_parent()
	await esperar(0.6)
	verificar(not is_instance_valid(casca), "inimigo derrotado e removido")

func testar_carrinho() -> void:
	var juiz = criar("juiz", 640.0)
	juiz.get_node("AnimationPlayer").speed_scale = 0.0
	Input.action_press("carrinho")
	await esperar(0.5)
	Input.action_release("carrinho")
	verificar(juiz.vida == 1, "carrinho causa somente um dano por inimigo")
	await esperar(0.35)
	verificar(not jogador.get_node("CollisionShape2D").disabled and jogador.get_node("ColisaoCarrinho").disabled, "colisao normal e restaurada apos carrinho")
	await limpar()
	var goleiro = criar("goleiro", 640.0)
	goleiro.set_physics_process(false)
	Input.action_press("carrinho")
	await esperar(0.5)
	Input.action_release("carrinho")
	verificar(goleiro.vida == 2, "carrinho tambem acerta goleiro")

func testar_var() -> void:
	var robo = criar("var", 500.0)
	verificar(robo.vida == 2, "VAR inicia com duas vidas")
	jogador.invulneravel = 100.0
	verificar(not robo.receber_dano(1, "bola") and not robo.receber_dano(1, "carrinho"), "VAR resiste a bola e carrinho")
	verificar(robo.global_position.y < 430.0 and not robo.receber_dano(1, "pisao"), "VAR comeca alto e sem brecha para pisada")
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	await esperar(1.1)
	verificar(not robo.derrotado, "pular imediatamente nao elimina o VAR alto")
	var x_inicial: float = robo.global_position.x
	var vistos: Dictionary = {}
	var disparos: Array[float] = []
	for i in 400:
		await get_tree().physics_frame
		observar_lasers(robo, vistos, disparos)
		if robo.estado_voo == robo.EstadoVoo.BRECHA:
			break
	verificar(robo.estado_voo == robo.EstadoVoo.BRECHA and robo.get_node("Brecha").visible and robo.global_position.y > 525.0, "VAR desce e sinaliza uma brecha alcancavel")
	verificar(absf(robo.global_position.x - x_inicial) > 5.0, "VAR se reposiciona antes de abrir a brecha")
	verificar(disparos.size() == 4, "VAR completa duas sequencias de dois lasers antes da brecha")
	verificar(disparos.size() == 4 and absf(disparos[2] - disparos[1] - 1.0) < 0.08, "duas sequencias guardam intervalo de um segundo entre lasers")
	jogador.global_position.x = robo.global_position.x
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	var pisou := false
	var rebateu := false
	for i in 80:
		await get_tree().physics_frame
		if is_instance_valid(robo) and robo.vida == 1:
			pisou = true
			if jogador.velocity.y < 0.0:
				rebateu = true
			break
	verificar(pisou and rebateu and not robo.derrotado, "primeiro pulo real tira uma vida e faz jogador quicar")
	verificar(robo.estado_voo == robo.EstadoVoo.SUBINDO and not robo.receber_dano(1, "pisao"), "primeira pisada fecha a brecha e exige nova rodada")
	for i in 400:
		await get_tree().physics_frame
		observar_lasers(robo, vistos, disparos)
		if robo.estado_voo == robo.EstadoVoo.BRECHA:
			break
	verificar(disparos.size() == 8 and robo.estado_voo == robo.EstadoVoo.BRECHA, "VAR repete duas sequencias antes de aceitar a segunda pisada")
	jogador.global_position.x = robo.global_position.x
	Input.action_press("pular")
	await esperar(0.05)
	Input.action_release("pular")
	var eliminado := false
	for i in 80:
		await get_tree().physics_frame
		if is_instance_valid(robo) and robo.derrotado:
			eliminado = true
			break
	verificar(eliminado, "segundo pulo real derrota o VAR")
	verificar(Global.qtd_vidas == 1000, "pisao no VAR nao causa dano ao jogador")

func observar_lasers(robo: Node, vistos: Dictionary, instantes: Array[float]) -> void:
	for no in get_children():
		if no.get_script() != null and no.get_script().resource_path.ends_with("script_laser.gd") and no.emissor == robo and not vistos.has(no.get_instance_id()):
			vistos[no.get_instance_id()] = true
			instantes.append(float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second)

func testar_goleiro() -> void:
	var goleiro = criar("goleiro", 780.0)
	var preparou := false
	for i in 90:
		await get_tree().physics_frame
		if goleiro.estado == goleiro.Estado.PREPARANDO:
			preparou = true
			break
	verificar(preparou and goleiro.get_node("Aviso").visible, "goleiro sinaliza antes do mergulho")
	verificar(goleiro.global_position.x < 680.0, "goleiro fecha a distancia com aproximacao mais ativa")
	var direcao_travada: int = goleiro.direcao_inimigo2
	jogador.global_position.x = goleiro.global_position.x + 200.0
	await esperar(0.25)
	verificar(goleiro.direcao_inimigo2 == direcao_travada, "goleiro nao vira durante preparacao")
	for i in 70:
		await get_tree().physics_frame
		if goleiro.estado == goleiro.Estado.MERGULHO:
			break
	verificar(goleiro.estado == goleiro.Estado.MERGULHO and not goleiro.get_node("Aviso").visible, "mergulho comeca apos o aviso")
	var inicio_mergulho: float = goleiro.global_position.x
	goleiro.causar_dano_personagem(jogador)
	verificar(Global.qtd_vidas == 999, "mergulho pode causar dano")
	await esperar(0.72)
	verificar(goleiro.estado == goleiro.Estado.RECUPERANDO and absf(goleiro.velocity.x) < 1.0, "goleiro para para recuperar apos mergulho")
	verificar(absf(goleiro.global_position.x - inicio_mergulho) > 460.0, "mergulho alcanca mais de 460 pixels")
	jogador.invulneravel = 0.0
	goleiro.causar_dano_personagem(jogador)
	verificar(Global.qtd_vidas == 999, "recuperacao permite contato sem dano")
	verificar(goleiro.receber_dano(1, "bola"), "goleiro recebe dano na recuperacao")
	await esperar(0.45)
	verificar(goleiro.receber_dano(1, "bola"), "segundo acerto no goleiro")
	await esperar(0.4)
	verificar(goleiro.receber_dano(1, "carrinho") and goleiro.derrotado, "goleiro derrotado apos tres acertos")

func testar_ciclo_var() -> void:
	var robo = criar("var", 500.0)
	robo.quantidade_lasers = 3
	jogador.invulneravel = 100.0
	var brecha_encontrada := false
	var vistos: Dictionary = {}
	var disparos: Array[float] = []
	for i in 400:
		await get_tree().physics_frame
		observar_lasers(robo, vistos, disparos)
		if robo.estado_voo == robo.EstadoVoo.BRECHA:
			brecha_encontrada = true
			break
	verificar(brecha_encontrada, "VAR abre brecha sem exigir dano previo")
	verificar(disparos.size() == 6 and absf(disparos[3] - disparos[2] - 1.0) < 0.08, "VAR de tres lasers tambem completa duas sequencias com intervalo de um segundo")
	var x_brecha: float = robo.global_position.x
	jogador.global_position.x += 180.0
	await esperar(0.4)
	verificar(absf(robo.global_position.x - x_brecha) < 5.0, "VAR permanece previsivel durante a brecha")
	var voltou_ao_alto := false
	for i in 220:
		await get_tree().physics_frame
		if robo.estado_voo == robo.EstadoVoo.ALTO:
			voltou_ao_alto = true
			break
	await esperar(0.05)
	verificar(voltou_ao_alto and robo.global_position.y < 430.0 and robo.collision_layer == 0, "brecha termina e VAR sobe novamente")
	verificar(not robo.receber_dano(1, "pisao"), "VAR nao recebe pisada depois que sobe")
	verificar(absf(robo.global_position.x - robo.origem_x) <= 460.0, "voo permanece dentro do encontro")

func testar_laser() -> void:
	var robo = criar("var", 600.0)
	robo.vida = 1 # Isola o cancelamento de lasers no golpe fatal.
	await esperar(0.05)
	robo.disparar_laser()
	await esperar(0.22)
	var lasers: Array[Node] = []
	for no in get_children():
		if no.get_script() != null and no.get_script().resource_path.ends_with("script_laser.gd"):
			lasers.append(no)
	verificar(lasers.size() == 2, "VAR gera sua sequencia de lasers")
	robo.mudar_estado_voo(robo.EstadoVoo.BRECHA)
	robo.receber_dano(1, "pisao")
	await esperar(0.1)
	var apagados := true
	for laser in lasers:
		if is_instance_valid(laser):
			apagados = false
	verificar(apagados, "derrotar VAR cancela lasers ativos")

func testar_limites() -> void:
	jogador.global_position.x = 12920.0
	Input.action_press("ir_para_direita")
	await esperar(0.5)
	Input.action_release("ir_para_direita")
	verificar(jogador.global_position.x < 13032.0 and jogador.is_on_floor(), "limite final mantem jogador dentro do mapa menor")
	jogador.global_position.x = 50.0
	Input.action_press("ir_para_esquerda")
	await esperar(0.3)
	Input.action_release("ir_para_esquerda")
	verificar(jogador.global_position.x > 0.0, "limite inicial mantem jogador dentro do mapa")

# As aventuras de um jogador

## Abrir e jogar

1. Extraia o ZIP inteiro para uma pasta.
2. Importe `project.godot` no Godot 4 e aguarde a importação das imagens.
3. Pressione F5 para abrir o menu inicial e clique em **Jogar**. F6 com `Cenario/cena_fase.tscn` aberta continua disponível para testar a fase diretamente.

O jogo abre maximizado, com base em 1280 × 720 e preenchimento adaptável ao formato do monitor. F11 alterna entre tela cheia e janela maximizada. A câmera aproxima os personagens em 20% em relação à versão anterior, ajustando o enquadramento em telas mais altas. Para aproveitar o monitor ao testar pelo Godot, execute o jogo em uma janela separada do painel do editor.

O projeto foi validado no Godot 4.6.1, com renderização GL Compatibility.
A pasta `.godot` é gerada novamente pelo editor e não precisa acompanhar o ZIP.

| Ação | Tecla |
| --- | --- |
| Tela cheia / janela maximizada | F11 |
| Andar | A/D ou setas esquerda/direita |
| Pular | W ou seta para cima |
| Chutar bolas | C (pode manter pressionado) |
| Carrinho | Espaço (pressione novamente para cada carrinho) |
| Pausar / continuar | Esc |
| Navegar nos menus | Mouse, setas ou Tab; Enter confirma |

## Início, pausa e final da partida

As quatro telas usam as imagens anexadas, preservadas na resolução original, com áreas clicáveis alinhadas aos botões. O menu principal, a pausa, a vitória e o Game Over preenchem toda a área da janela do jogo. Imagem e botões acompanham a largura e a altura disponíveis, sem margens e sem cortar botões ao redimensionar.

- **Início:** usa `Menu_Principal.png`, com Jogar, Controles e Configurações.
- **Controles:** mostra `painel_controles.png` centralizado, sem alterar a imagem ou sua proporção, sobre fundo verde da mesma paleta. O painel ocupa no máximo 72% da largura ou da altura da janela (`OCUPACAO_CONTROLES` em `Cenario/telas/tela_menu.gd`) e nunca passa do tamanho original da imagem. Voltar ou Esc retorna ao menu com o foco em Controles. Abrir esse painel não reinicia a faixa de abertura.
- **Pausa:** Continuar, Reiniciar, Configurações e Sair. Esc abre e fecha a pausa; Sair retorna ao menu inicial. Movimento, inimigos, projéteis e duração dos efeitos ficam congelados enquanto a pausa está aberta.
- **Game Over:** aparece quando as vidas chegam a zero, com Tentar novamente e Menu principal.
- **Vitória:** ao chegar ao pódio final, pule para encostar na taça. A coleta é automática e abre a imagem de campeão, com pontuação, Jogar novamente e Menu principal. Apenas chegar ao fim do mapa não encerra a partida.

Jogar, Reiniciar, Tentar novamente e Jogar novamente começam a fase do início, com 5 vidas e pontuação zero. As trocas entre telas usam um breve escurecimento. As configurações oferecem **Som ligado/desligado** e **Invencibilidade**, ficam disponíveis no início e na pausa e são salvas para as próximas execuções. Esc nas configurações fecha primeiro esse painel.

O controle **Som** liga/desliga todas as músicas, a torcida e os efeitos. A invencibilidade bloqueia dano e lentidão do cartão vermelho, e exibe `INVENCÍVEL` no HUD. Ela começa desligada na primeira execução.

A taça interativa usa `Taca.png`, sobreposta à taça pintada no cenário, com posição e área de coleta ajustáveis em `Cenario/taca.tscn`. Ela levita suavemente, subindo e descendo 5 pixels em um ciclo de 2,4 segundos; a área de coleta acompanha a imagem e a animação congela durante a pausa. A amplitude e o período podem ser ajustados no nó da taça pelo inspetor.

O nó `FundoDoPodio` reutiliza um pequeno trecho da torcida para ocultar a taça pintada no fundo durante a levitação. Os arquivos PNG originais permanecem intactos.

## Áudio

Os 16 áudios enviados estão em `Audio/Importados/`, preservados sem alteração. Os volumes são ajustados na reprodução, sem modificar as gravações.

| Situação | Áudio e comportamento |
| --- | --- |
| Botões | `apertar_botao.mp3` ao confirmar por mouse ou teclado, inclusive na pausa e nas trocas de tela. Respeita Som desligado. |
| Menu inicial | `trilha_menuprincipal.mp3` toca uma vez; depois fica em silêncio até iniciar a partida. Retornar ao menu toca a abertura novamente. Abrir Configurações não a reinicia. |
| Partida inteira | `trilha_jogo.wav` toca em loop, inclusive no estádio. |
| Interior do estádio | `trilha_estadio.wav` toca em loop junto da música principal, a partir do panorama `cenario_completo.png`. Ao voltar para fora, apenas a torcida é interrompida. |
| Pausa | Música, torcida e efeitos da partida congelam no ponto atual. Continuar retoma a reprodução. Os botões e configurações da pausa continuam tocando o som de clique quando Som está ligado. |
| Chute / carrinho / pulo do jogador | `ataque_jogador.mp3`, `jogador_carrinho.wav` e `pulo_jogador.wav`, respectivamente. |
| Dano no jogador | `dano_jogador.wav` apenas quando o dano é aceito. Proteção temporária e invencibilidade não emitem falso som de dano. |
| Juiz | `ataque_juiz.mp3` no lançamento de cada cartão e `dano_juiz.mp3` ao receber dano. |
| VAR | `ataque_var.mp3` uma vez por sequência de lasers e `dano_var.wav` ao receber a pisada durante a brecha. |
| Goleiro | `ataque_goleiro.wav` uma vez no início de cada mergulho e `dano_goleiro.mp3` quando recebe dano. |
| Vitória / Game Over | `vitoria.wav` ou `gameover.wav` toca uma vez ao abrir a tela correspondente. As trilhas da partida param para destacar o resultado. |

A música, a torcida e os resultados usam canais próprios para que os ataques não cortem essas faixas. A música fica em volume mais baixo que os efeitos, e a torcida foi equilibrada considerando o nível mais baixo da gravação original. Os ajustes em decibéis ficam em `Cenario/global.gd`.

## Cenário

Uma fase contínua com 13.032 pixels de largura, chão plano e câmera limitada às bordas.
O mapa usa três imagens externas e um único panorama contínuo no interior do estádio, nesta ordem:

`01_inicio → 02_cidade → 03_estadio → cenario_completo`.

O arquivo `cenario_completo.png` substitui as antigas imagens 04, 05 e 06. Ele cobre toda a extensão anterior do interior, com escala uniforme para preservar a proporção e sem emendas entre esses trechos. O panorama usa a imagem em alta resolução (6516 × 746 px, escala 1:1), sem ampliação, e filtro padrão do projeto. O mapa mantém os 13 encontros e o mesmo comprimento total.

As imagens e os inimigos podem ser reposicionados no editor, em `Cenarios` e `Inimigos`, dentro de `Cenario/cena_fase.tscn`.
Os encontros ficam mais próximos ao longo do percurso; os VARs posteriores disparam três lasers por sequência em vez de dois. Cada ciclo tem duas sequências completas.
A imagem 02 mantém a cidade com o viaduto. A imagem enviada na correção foi aplicada como `03_estadio`, com a fachada do estádio.

Entre `01_inicio` e `02_cidade` (`Trecho01` e `Trecho02`) não há passagem: o jogador segue andando, e a emenda em x = 2172 é escondida por uma faixa de mesclagem, `Cenario/sprite/emenda_01_02.png` (1040 × 724 px), no nó `Emendas/Emenda01_02` da fase. Ela harmoniza a cor das duas bordas de forma gradual (céu e gramado), dissolve nuvens, árvores e cerca numa faixa curta e corrige a diferença de 4 px na altura dos dois sprites. As imagens originais e as posições dos trechos não foram alteradas; a faixa fica fora de `Cenarios` para não criar uma área nova nem mudar os limites dos encontros. Para refazê-la depois de trocar uma das imagens, execute `python3 Ferramentas/gerar_emenda_01_02.py` (requer numpy, Pillow e scipy); os ajustes de largura e intensidade ficam no início do script. Para desfazer o efeito, basta remover o nó `Emendas`.

Entre `02_cidade` e `03_estadio`, há uma passagem sob o viaduto, com estrutura em primeiro plano e escurecimento breve para esconder a emenda. A volta pelo mesmo caminho também funciona.

Entre `03_estadio` e `cenario_completo`, o jogador atravessa um túnel com escurecimento de 0,25 s, uma pausa de 0,18 s e revelação de 0,30 s. A câmera mostra apenas um lado por vez, escondendo a emenda. O percurso funciona também no sentido contrário; combate e movimento ficam pausados durante a troca.

O panorama do estádio foi aplicado a partir do anexo original, com início, meio e final conferidos no jogo. As imagens externas permanecem nas mesmas posições.

## Jogador

O jogador ficou 15% maior em relação à versão anterior, sem aumentar os inimigos ou aproximar novamente a câmera. As colisões em pé e no carrinho foram ajustadas, mantendo os pés na mesma altura.

## Inimigos e dano

| Inimigo | Quantidade | Vida | Como derrotar |
| --- | --- | --- | --- |
| Juiz | 5 | 2 | Bolas e carrinho |
| Goleiro | 5 | 3 | Bolas e carrinho |
| VAR | 3 | 2 | Duas pisadas, em brechas diferentes |

- Cada bola e cada carrinho causam um ponto de dano. O mesmo carrinho só acerta cada inimigo uma vez.
- Inimigos piscam em vermelho e têm 0,35 s de proteção após cada acerto; ao perder toda a vida, desaparecem.
- O amarelo causa um ponto de dano ao jogador.
- O vermelho causa um ponto de dano e reduz a velocidade para 55% por 2,5 s. A indicação `LENTO` aparece acima do jogador.
- O juiz alterna os cartões, inclusive quando o jogador sai e volta ao alcance. A cor segue a animação e a direção é fixada no lançamento. O intervalo entre cartões é de aproximadamente 1,5 s, reduzido de 1,8 s.
- O jogador tem 0,4 s de proteção após receber dano. A lentidão não se acumula em multiplicadores.
- O VAR inicia em voo alto, fora do alcance do pulo comum, patrulhando lateralmente. Completa duas sequências de lasers antes de descer, com 1 s entre o último laser da primeira sequência e o primeiro da segunda. Cada sequência mantém dois ou três lasers, conforme o encontro, e toca um único som de ataque.
- Depois dos ataques, o VAR desce até uma posição próxima do jogador e fica vulnerável por até 1,65 s. A indicação verde `↓ BRECHA` marca essa oportunidade. Se a oportunidade passar, ele sobe e repete os ataques.
- O VAR só recebe a pisada enquanto a brecha está aberta. A primeira pisada tira uma vida, impulsiona o jogador e faz o VAR subir imediatamente. Ele repete as duas sequências antes de abrir outra brecha; a segunda pisada o derrota. Fora da brecha o jogador atravessa seu corpo, para evitar eliminá-lo apenas esperando em cima dele.
- Bolas e carrinho não derrotam o VAR. Derrotá-lo também cancela seus lasers ativos.
- Cartões e bolas expiram após um tempo para não se acumularem fora da tela.

## Goleiro

O encontro segue guarda/aproximação → preparação agachada com aviso `!` → mergulho → recuperação.
A preparação dura 0,55 s, o mergulho aproximadamente 0,65 s e a recuperação 0,85 s. A aproximação aumentou de 160 para 420 px/s e o mergulho de 560 para 820 px/s, cobrindo cerca de 530 pixels em terreno livre. A perseguição fica limitada ao encontro para evitar atravessar o mapa todo atrás do jogador.
O goleiro fixa a direção durante a preparação; passar para trás dele permite esquivar.
Na recuperação ele fica parado e não causa dano de contato. Pular ou usar o trecho ativo do carrinho permite evitar o mergulho.

Os ajustes estão exportados no corpo do goleiro: `vida_maxima`, `tempo_preparacao`, `tempo_recuperacao` e `velocidade_mergulho`, `velocidade_aproximacao` e `duracao_mergulho`.
`vida_maxima` e `alcance_ativacao` também ficam disponíveis nos outros inimigos.

## Arquivos principais

| Arquivo | Responsabilidade |
| --- | --- |
| `Cenario/cena_fase.tscn` | Percurso, imagens, chão, limites e encontros |
| `Cenario/global.gd` | Estado da partida, configurações, pausa, áudio e transições entre telas |
| `Cenario/telas/tela_menu.gd` | Telas, botões, foco do teclado, layout e painel de configurações |
| `Cenario/taca.tscn` e `.gd` | Taça do pódio e coleta automática que dispara a vitória |
| `Cenario/telas/assets/` | Imagens originais das telas e da taça |
| `Audio/` e `Audio/Importados/` | Efeitos anteriores e gravações enviadas em WAV/MP3 |
| `Cenario/transicao_estadio.tscn` e `.gd` | Viaduto, túnel, escurecimento e limites de câmera coordenados entre as regiões |
| `Cenario/sprite/emenda_01_02.png` e `Ferramentas/gerar_emenda_01_02.py` | Faixa que suaviza a junção entre `Trecho01` e `Trecho02`, e o gerador dela |
| `Personagem/inimigo_base.gd` | Vida, proteção, efeito vermelho e derrota |
| `Personagem/jogador/script_personagem.gd` | Movimento, carrinho, dano, lentidão e pisada |
| `Personagem/jogador/script_bola.gd` | Movimento e colisão das bolas |
| `Personagem/inimigo_juiz/script/` | Arremessos e efeito dos cartões |
| `Personagem/inimigo_goleiro/script/goleiro.gd` | Etapas do ataque do goleiro |
| `Personagem/inimigo_var/script/` | Voo, pisada e lasers |

## Verificação automatizada

Execute `Testes/combate.tscn` no editor, ou use:

```sh
godot --headless --path . res://Testes/combate.tscn
godot --headless --path . res://Testes/transicao.tscn
godot --headless --path . --script res://Testes/telas.gd
godot --headless --path . --script res://Testes/audio.gd
```

Resultado desta versão: **170 verificações, zero falhas** (66 de combate, 24 de transição, 41 de telas e 39 de áudio) no Godot 4.6.1.

O teste executa as cenas e a física reais e verifica cenário, direção e alternância dos cartões, dano, lentidão, bolas, carrinho, pisada, etapas do goleiro, cancelamento dos lasers e limites do mapa. Também verifica o intervalo maior dos cartões, o voo alto do VAR, a janela real de pisada e o retorno ao voo quando a oportunidade passa. O resultado aparece no console; o processo retorna zero quando passa.

O novo balanceamento é verificado com arremessos reais a cada 1,5 s, duas sequências completas do VAR com intervalo de 1 s (tanto no padrão de dois quanto no de três lasers), duas pisadas reais em ciclos separados e reinícios com 5 vidas. O painel de controles foi conferido com mouse, teclado, Esc e Voltar, incluindo centralização e cliques reais em 1440 × 900 e 2560 × 1080.

Também foi conferida a renderização dos cenários, uma travessia completa do percurso e as imagens da entrada, escurecimento e saída do túnel. A abertura maximizada e o F11 foram verificados em 1920 × 1080, inclusive com o jogo pausado. Os 24 testes de transição incluem ida e volta pelo viaduto, percurso até o túnel seguinte e limites de câmera corretos após cada passagem.

Os testes de telas verificam o menu inicial, navegação por teclado, opções de som, persistência das configurações, invencibilidade, pausa da física e dos efeitos, reinícios, retorno ao menu, Game Over e coleta real da taça durante o pulo. As quatro telas e o painel de configurações também foram conferidos em 1920 × 1080; os botões do menu inicial e do final foram acionados por eventos reais de mouse.

O preenchimento das quatro telas e seus cliques foram conferidos também em 1440 × 900 e 2560 × 1080. A levitação foi inspecionada nas duas extremidades do movimento, incluindo o acompanhamento da colisão e o congelamento na pausa.

Os testes de áudio verificam os eventos reais de pulo, chute, carrinho, cartões, sequência de lasers e dano; abertura sem repetição; loops completos de música e torcida; entrada e saída do estádio; interrupção nos resultados; volume geral desligado; e posição de reprodução congelada na pausa e retomada ao continuar. A validação automatizada usa o driver de áudio do ambiente de teste; o equilíbrio percebido dos volumes pode ser refinado ao jogar no computador de destino.

Checkpoints ficam para uma próxima etapa.

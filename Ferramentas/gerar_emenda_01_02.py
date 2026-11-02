#!/usr/bin/env python3
"""Gera Cenario/sprite/emenda_01_02.png, a faixa que suaviza a juncao entre
Trecho01 (01_inicio.png) e Trecho02 (02_cidade.png) em Cenario/cena_fase.tscn.

As imagens originais NAO sao alteradas. A faixa e um sprite extra, desenhado por
cima da juncao, que:
  1. harmoniza a cor das duas bordas de forma gradual (largura LARGURA_COR);
  2. dissolve a estrutura (nuvens, arvores, cerca) numa faixa curta (LARGURA_ESTRUTURA),
     usando o reflexo de cada imagem alem da propria borda;
  3. corrige o desalinhamento vertical entre os dois sprites (y=-5 e y=-1 na cena).

Os numeros abaixo precisam bater com cena_fase.tscn (posicao e escala dos Trechos).
Uso: python3 Ferramentas/gerar_emenda_01_02.py   (requer numpy, Pillow e scipy)
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d

RAIZ = Path(__file__).resolve().parent.parent
SPRITES = RAIZ / "Cenario" / "sprite"

# --- valores de cena_fase.tscn -------------------------------------------------
ESCALA_X, ESCALA_Y = 1.0605469, 1.0615835
Y_A, Y_B = -5.0, -1.0            # posicao y de Trecho01 e Trecho02
EMENDA_X = 2172                  # x da juncao (posicao x de Trecho02)
ALTURA = 724                     # altura do mundo (limite inferior da camera)

# --- ajustes da faixa ----------------------------------------------------------
LARGURA_COR = 520                # px de cada lado em que a cor e harmonizada
LARGURA_ESTRUTURA = 60           # px de cada lado em que as imagens se dissolvem
SUAVIZAR_COR_Y = 28.0            # desfoque vertical da correcao de cor (evita listras)
LIMITE_COR = 70.0                # correcao maxima por canal (0-255)


def suave(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def carregar_mundo(nome):
    img = Image.open(SPRITES / nome).convert("RGB")
    largura = round(img.width * ESCALA_X)
    altura = round(img.height * ESCALA_Y)
    return np.asarray(img.resize((largura, altura), Image.BILINEAR), dtype=np.float32)


def amostrar_linhas(img, linhas):
    """Amostra img (H, W, 3) em linhas fracionarias (H_saida, N) -> (H_saida, N, 3)."""
    h = img.shape[0]
    linhas = np.clip(linhas, 0.0, h - 1.001)
    i0 = np.floor(linhas).astype(int)
    f = (linhas - i0)[..., None]
    colunas = np.arange(linhas.shape[1])[None, :]
    return img[i0, colunas] * (1.0 - f) + img[i0 + 1, colunas] * f


def main():
    a = carregar_mundo("01_inicio.png")
    b = carregar_mundo("02_cidade.png")
    assert a.shape[1] == EMENDA_X, f"Trecho01 deveria ter {EMENDA_X} px, tem {a.shape[1]}"

    meia = LARGURA_COR
    xs = np.arange(EMENDA_X - meia, EMENDA_X + meia)          # colunas do mundo
    n = xs.size
    ys = np.arange(ALTURA, dtype=np.float32)[:, None]          # linhas do mundo

    # Colunas de cada imagem, com reflexo alem da propria borda.
    col_a = np.where(xs < EMENDA_X, xs, 2 * EMENDA_X - 1 - xs)
    local_b = xs - EMENDA_X
    col_b = np.where(local_b >= 0, local_b, -local_b - 1)
    col_a = np.clip(col_a, 0, a.shape[1] - 1)
    col_b = np.clip(col_b, 0, b.shape[1] - 1)

    # Correcao vertical: ambas convergem para y = media dos dois sprites na juncao.
    y_comum = (Y_A + Y_B) / 2.0
    u_a = suave((xs - (EMENDA_X - meia)) / meia)               # 0 longe, 1 na juncao
    u_b = suave(((EMENDA_X + meia) - xs) / meia)
    desloc_a = (y_comum - Y_A) * u_a                           # sobe/desce a imagem A
    desloc_b = (y_comum - Y_B) * u_b
    linhas_a = ys - (Y_A + desloc_a)[None, :]
    linhas_b = ys - (Y_B + desloc_b)[None, :]
    faixa_a = amostrar_linhas(a[:, col_a], linhas_a)
    faixa_b = amostrar_linhas(b[:, col_b], linhas_b)

    # Harmonizacao de cor: a diferenca entre as bordas, por linha, e repartida
    # meio a meio e aplicada de forma crescente ate a juncao.
    borda_a = a[:, -6:].mean(axis=1)
    borda_b = b[:, :6].mean(axis=1)

    def para_mundo(borda, y0):
        idx = np.clip(np.arange(ALTURA) - y0, 0, borda.shape[0] - 1).astype(int)
        return borda[idx]

    delta = para_mundo(borda_b, Y_B) - para_mundo(borda_a, Y_A)
    delta = gaussian_filter1d(delta, SUAVIZAR_COR_Y, axis=0, mode="nearest")
    delta = np.clip(delta, -LIMITE_COR, LIMITE_COR)
    peso_a = 0.5 * suave((xs - (EMENDA_X - meia)) / meia)
    peso_b = 0.5 * suave(((EMENDA_X + meia) - xs) / meia)
    faixa_a = faixa_a + delta[:, None, :] * peso_a[None, :, None]
    faixa_b = faixa_b - delta[:, None, :] * peso_b[None, :, None]

    # Dissolucao estrutural curta e centrada na juncao.
    peso_dissolver = suave((xs - (EMENDA_X - LARGURA_ESTRUTURA)) / (2.0 * LARGURA_ESTRUTURA))
    mistura = faixa_a * (1.0 - peso_dissolver)[None, :, None] + faixa_b * peso_dissolver[None, :, None]

    # Bordas externas da faixa somem aos poucos para encaixar nas imagens originais.
    distancia_borda = np.minimum(xs - xs[0], xs[-1] - xs)
    alfa = suave(distancia_borda / (0.18 * meia))
    saida = np.dstack([np.clip(mistura, 0, 255), alfa[None, :].repeat(ALTURA, axis=0) * 255.0])
    destino = SPRITES / "emenda_01_02.png"
    Image.fromarray(saida.astype(np.uint8), "RGBA").save(destino, optimize=True)
    print(f"Gerado {destino.relative_to(RAIZ)}: {n} x {ALTURA} px, "
          f"posicao x = {int(xs[0])} na cena")


if __name__ == "__main__":
    main()

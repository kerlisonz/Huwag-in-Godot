# Folha de Estilo e Direção de Arte — Huwag (Godot 4)

## 1. Resolução-Base, Escala e Perspectiva Top-Down 3/4

- **Resolução nativa da viewport:** `640 × 360` px (16:9), escalada em `canvas_items` (`expand`) para `1280 × 720`, `1920 × 1080` e resoluções ultrawide/4:3 sem deformação.
- **Modos de renderização de texturas:**
  - `Nearest` para o mundo 2D, sprites e tiles, preservando os pixels nítidos.
  - `Linear with Mipmaps` exclusivo para os retratos anime de diálogo em alta resolução (`512 × 512` px).
- **Unidade de grade (Tile / Célula):** `32 × 32` px, compatível com os submódulos de `16 × 16` px de marcenaria e pisos.
- **Perspectiva:** Top-down oblíqua 3/4 (preservando 100% da jogabilidade top-down do projeto, sem converter o mapa para isométrico nem para visão lateral).

---

## 2. Ficha de Consistência Canônica — Huwag Matitiis (Fonte de Verdade: Imagem 3)

A **Imagem 3** aprovada pelo usuário é a referência mestre canônica para a aparência de **Huwag Matitiis** (23 anos, bombeiro municipal em Agdangan, Quezon). Nenhuma expressão derivada ou sprite pode redesenhar ou alterar sua estrutura facial e capilar:

| Elemento | Especificação Canônica (Invariante entre Retratos, Sprites e Animações) | Paleta-Base Canônica (Extraída da Imagem 3) |
| :--- | :--- | :--- |
| **Cabelo (Forma, Volume e Raízes)** | Cabelo curto, volumoso e bagunçado em mechas espetadas irregulares para os lados e topo, com mechas frontais caindo em "V" sobre a testa. **Raízes, centro da coroa, costeletas e nuca em preto profundo** (`#141218`), com pontas e camada superior **descoloridas em loiro-palha claro** (`#EBE2A6` / `#D8CF92`). | Pontas claras `#EBE2A6` / Sombra loira `#C7BC7D` / Raiz preta `#141218` |
| **Rosto, Olhos e Olheiras** | Jovem filipino de 23 anos, rosto oval-angular com queixo definido, nariz médio com brilho sutil na ponta, sobrancelhas pretas espessas e expressivas, olhos escuros amendoados e **olheiras profundas e escuras marcadas com hachuras de nanquim** sob as pálpebras inferiores (exaustão e insônia crônica). | Pele base `#9E724D` / Sombra `#724F34` / Olheiras `#4A3225` / Brilho `#C49A71` |
| **Traço e Sombreamento** | Contorno expressivo em nanquim preto (`#0E0D12`) com variação orgânica de espessura e hachuras nas áreas de sombra do pescoço, clavícula, olheiras e dobras de tecido. | Nanquim `#0E0D12` / Hachura `#261C18` |
| **Traje 1 — Roupa Casual (`"casual"`, Imagem 3)** | Jaqueta escura cinza-carvão/preta (`#232328` / `#151519`) de gola larga aberta com fechos discretos na lapela, vestida sobre camiseta preta de gola careca (`#141418`), calça escura/cáqui-acinzentada (`#383B36`) e tênis escuros com sola clara. | Jaqueta `#232328` / Sombra `#121216` / Camiseta `#141418` / Calça `#383B36` |
| **Traje 2 — Uniforme de Bombeiro BFP (`"bfp"`)** | Casaco pesado azul-marinho/grafite do *Bureau of Fire Protection (BFP)* (`#23293A`) com gola alta estruturada aberta sobre camiseta escura, **faixas refletivas horizontais amarelo-ouro e laranja de segurança** (`#F5CB5C` / `#E86F24`) com fita central prateada, fechos metálicos e brasão BFP na manga. | Casaco BFP `#23293A` / Faixa Amarela `#F5CB5C` / Faixa Laranja `#E86F24` |

---

## 3. Configuração do Personagem Jogável Definitivo (Huwag Canônico em `Player.tscn` / `player.gd`)

O protagonista jogável utiliza os spritesheets canônicos 4-direcionais de Huwag (`huwag_casual_sheet.png` e `huwag_bfp_sheet.png` em `res://assets/characters/sprites/`), preservando integralmente a identidade visual aprovada da Imagem 3 (cabelo loiro descolorido espetado com raízes pretas, pele morena filipina, porte jovem e trajes casual/BFP):

- **Geometria das Células (`480 × 192` px total, células de `48 × 48` px):**
  - Grid de 10 colunas por 4 linhas direcionais:
    - Linha 0: Frente / Sul (`down`)
    - Linha 1: Esquerda / Oeste (`left`)
    - Linha 2: Direita / Leste (`right`)
    - Linha 3: Costas / Norte (`up`)
  - Com `centered = true` e `offset = Vector2(0.0, -8.0)`, os pés do sprite tocam exatamente em `Y = +10` (`42 - 24 - 8 = +10`), alinhados milimetricamente com a base do `CollisionShape2D` (`position = Vector2(0, 4)`, `size = Vector2(14, 12)`).
  - Troca dinâmica em tempo real entre `huwag_casual_sheet.png` e `huwag_bfp_sheet.png` acionada por `GameState.equipped_outfit` (via armário, tecla `O` ou enredo).
- **Animações 4-Direcionais Configuradas (`SpriteFrames`):**
  1. **`idle_down`, `idle_left`, `idle_right`, `idle_up`:** 2 quadros (colunas 0..1), 4 FPS, respiração sutil.
  2. **`walk_down`, `walk_left`, `walk_right`, `walk_up`:** 4 quadros (colunas 2..5), 9 FPS, passada firme.
  3. **`run_down`, `run_left`, `run_right`, `run_up`:** 4 quadros (colunas 2..5), 14 FPS ao segurar `Shift`.
  4. **`attack_down`, `attack_left`, `attack_right`, `attack_up`:** 4 quadros (colunas 6..9), 22 FPS, golpe direcional com o machado de bombeiro, sincronizado com o arco J-ABS de `44 px` e `120°`.
  5. **`crouch_down`, `crouch_left`, `crouch_right`, `crouch_up`:** 1 quadro (coluna 1), postura abaixada ao segurar `Ctrl` ou `X`.
  6. **`jump_down`, `jump_left`, `jump_right`, `jump_up`:** 1 quadro (coluna 2), impulso com arco parabólico vertical ao pressionar `V` ou `Espaço`.
  7. **Aliases de compatibilidade:** `idle`, `walk`, `run`, `attack`, `crouch`, `jump` mantidos como atalhos para a direção frontal (`down`).

---

## 4. Renovação dos Cenários e Coerência Visual (`scenes/levels/`)

Hierarquia visual aplicada aos quatro cenários reconstruídos: **(1) FNAF Minigames** (arcade top-down de horror com paleta cinza/preto/branco sujo e acentos pontuais), **(2) Yume Nikki** (vazio, surrealismo e elementos desconfortáveis na dose alta do Ato 2), **(3) Chrono Trigger** (composição espacial estruturada sem corredores genéricos) e **(4) Pokémon Game Boy** (escala clara de edifícios, calçadas, estradas e NPCs). Distorções VHS mais intensas ficam restritas estrategicamente ao Ato 2 (dose maior) e sequências de trauma.

1. **Quarto de Huwag (`scenes/levels/room_huwag.gd` / `RoomHuwag.tscn`):**
   - Tilesets `interior_fnaf_normal` e `interior_fnaf_distorted` em grade `16×16` com alternância imediata ao escolher dose maior no Ato 2.
   - Mobília pessoal e narrativa ambiental (cama *papag*, tapete em xadrez arcade, escrivaninha com rádio/notas de turno, frascos de pílulas, prateleira com capacete/mini-Jeepney e pia/geladeira), com objetos que exibem pistas de culpa e estranheza sem poluir a leitura retrô.
2. **Quartel de Bombeiros (`scenes/levels/fire_station.gd` / `FireStation.tscn`):**
   - Planta multi-ala estruturada: Recepção/Espera, Sala de Despacho/Rádio, Galpão de Viaturas, Enfermaria e Escritório do Capitão Reyes.
   - NPCs do esquadrão em spritesheets dedicados de bombeiro (`Cap. Reyes`, `Bombeiro Ato`, `Bombeiro Santos`, `Enfermeira Maria`) com versões distorcidas no Ato 2 e confrontos hostis opcionais por escolhas de diálogo.
3. **Rua de Agdangan (`scenes/levels/street_preview.gd` / `StreetPreview.tscn`):**
   - Avenida estendida (`2880×560`) reinterpretando estrutura de cidade RPG clássica em paleta sombria FNAF: quarteirão da quitinete de Huwag, Central BFP de Agdangan destacada, calçadas, postes de iluminação com poças de luz/sombra, viatura/Jeepney, beco silencioso e mercado/esquina leste (`Barangay`).
   - NPCs distribuídos ao longo de toda a rua (`Aling Nena`, `Kuya Ben`, `Toby`, `Feirante` e aparições de `Luningning` / espectros na dose alta) com diálogos informativos e rotas narrativas até o Ato 3.
4. **Trilha da Floresta e Clareira da Lagoa (`scripts/levels/forest_trail.gd` e `scripts/levels/forest_clearing.gd`):**
   - **Trilha (`forest_trail.tscn` / `ForestCorridor.tscn`, `2560×768`):** percurso longo com bifurcações (Serra das Cinzas ao norte vs. Riacho da Cruz com duas pontes de tronco e ilha de suprimento ao sul), Bacia Silenciosa central estilo Yume Nikki, Poço Seco e Desfiladeiro em Brasas. Combate escalonado com 13 `SantelmoEnemy` crescentes (60 a 140 HP) + espectro `NPC_Vulto_Bosque` sem alterar a mecânica base de combate.
   - **Clareira (`forest_clearing.tscn` / `ForestClearing.tscn`, `960×576`):** anel de pedra retrô cercando a lagoa luminescente, ninho com ovos azuis, resgate do gato e espelho real da água no Ato 3.

---

## 5. Interface e Diálogo Compacto (`DialogueBox.tscn` / `dialogue_box.gd`)

1. **Caixa de Diálogo Compacta e Proporcional:**
   - Altura total reduzida para `86 px` ancorada na parte inferior (`offset_top = -94`, `offset_bottom = -8`), deixando mais de **76% da tela permanentemente visível** para visualização contínua do quarto e dos acontecimentos no cenário.
   - Tipografia pixelada nítida (`undertale-deltarune-extended-fixed.otf`) em tamanho 8–9 px, com espaçamento equilibrado e quebra automática de linha.
2. **Retrato Integrado em Busto Menor (`76 × 86` px):**
   - Retrato reduzido para busto compacto integrado ao painel no canto inferior esquerdo (`76 × 86` px), com transparência RGBA e sem molduras pesadas.
   - **Ocultação Automática em Monólogos Internos:** Durante narrações e pensamentos íntimos de Huwag (`is_monologue = true` ou `is_thought = true`), o slot do retrato e a haste vertical são automaticamente ocultados, expandindo a caixa de texto para a esquerda com acabamento chanfrado e foco total na leitura, sem poluir a cena.
   - **Diálogo com Interlocutor:** Em conversas bilaterais (ex: Rádio com Capitão Reyes), o interlocutor secundário surge no canto inferior direito (`ListenerCard`), mantendo a legibilidade e o dinamismo visual.

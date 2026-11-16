# Fichas de Personagem, Elenco e Especificação Técnica 96×96 — Fase 3 (`Huwag`)

> **Documento-Mestre — Passo 1 de 4 (Refatoração Completa da Fase 3)**  
> **Estilo-Alvo dos Sprites:** Pixel art orgânica desenhada à mão no nível de silhueta, volume e poses da referência das 4 classes (*arqueira, atiradora, espadachim e maga*), combinada ao clima sombrio de alto contraste e traço tipo nanquim (`#120C16`) do retrato canônico de **Huwag Matitiis**. Sem anti-aliasing, sem gradientes suaves, **3 a 4 tons definidos por material** (sombra, base, luz e brilho/dobra), sombra elíptica firme no chão, proporções estilizadas legíveis (pescoço, ombros, cintura, mãos e pés bem definidos — **zero corpos em bloco/chibi**) e **silhueta única** para cada personagem.  
> **Continuidade Narrativa (Invariante):** Preserva integralmente [continuidade-narrativa.md](continuidade-narrativa.md), [auditoria-original.md](auditoria-original.md), a ambientação em **Agdangan, Quezon (Filipinas)** e todos os 26 switches canônicos (`001` a `026`) em `scripts/autoload/game_state.gd`.

---

## 1. Especificação Técnica Oficial de Sprites, Armas, VFX e Retratos

### 1.1 Geometria, Fundo e Grade Regular
- **Tamanho único de quadro (`frame`):** **`96 × 96` px** em **TODOS** os arquivos, animações e direções (garantindo espaço amplo para proporções estilizadas de ~58 px de altura, movimento secundário e armas longas como machado, remo, chave inglesa e cutelo **sem invadir quadros vizinhos**).
- **Fundo e Limpeza:** PNG com fundo **100% transparente (canal alfa puro)** — zero caixas brancas, zero ruído de pontinhos soltos (detalhes como faixas refletivas do BFP serão barras/dobras limpas e legíveis).
- **Ancoragem invariante de escala e pés:** Em **absolutamente todos os frames** (inclusive queda e corpo no chão na animação de morte), o personagem mantém a **mesma escala/proporção** e o centro do apoio dos pés ancorado exatamente em **`(48, 82)`** na célula `96 × 96` px (sombra no chão centrada em `(48, 83)`), evitando qualquer "pulo" vertical ou horizontal.

### 1.2 Direções, Ciclos e Organização de Arquivos
- **8 Direções consistentes (com silhueta, volume e cabelo coerentes em todas):**
  `down`, `left`, `right`, `up`, `down_left`, `down_right`, `up_left`, `up_right`.  
  *(Quando laterais ou diagonais utilizarem espelhamento horizontal, toda a anatomia base e os dois lados de iluminação permanecem consistentes sem inverter brasões/assimetrias críticas, ou são desenhados assimetricamente quando necessário.)*
- **Uma linha por animação — nomenclatura padronizada por pasta:**
  Cada personagem vive em `res://assets/characters/<id>/`, com uma tira horizontal por `(animacao, direcao)` — ex.:
  - `sprites/<id>_<variant>_<anim>_<dir>.png` (1 linha × `N` quadros de `96 × 96` px)
  - `vfx/<id>_vfx_<anim>_<dir>.png` (**camada separada** de corte/fogo/impacto com o mesmo tamanho `96 × 96` px por célula e transparência alfa, aparecendo apenas nos quadros de impacto/smear e dissipação, alinhada pixel a pixel à trajetória da arma)
  - `<id>_atlas.json` (metadados oficiais: `character`, `variant`, `frame_size`, `anchor`, `animations` com `name`, `file`, `vfx_file`, `frames`, `fps`, `loop`, `impact_frame` e `phases`)
  - `gifs/<id>_<variant>_<anim>_<dir>.gif` (GIFs animados em fundo transparente para inspeção imediata no navegador/editor)
- **Padrão de quadros e fases por animação:**
  - `idle`: **6 frames** (respiração clara no tórax/ombros, inclinação leve, piscar natural e atraso no cabelo/roupa; `8 FPS`, loop).
  - `walk`: **8 frames** em ciclo contínuo de loop sem saltos (passada completa esquerda/direita, elevação de joelho, balanço oposto de braços, leve subida/descida do corpo e atraso secundário; `11 FPS`, loop).
  - `run`: **8 frames** em ciclo contínuo de loop (inclinação frontal, passada alongada, braços dobrados em propulsão, dobra/cabelo reagindo com atraso; `14 FPS`, loop).
  - **Combate — `attack` (6 frames em 3 fases nítidas, sem repetição de pose):**
    - *Fase 1 — Antecipação (`frames 0..1`):* recuo de peso, torção de ombros e arma armada atrás.
    - *Fase 2 — Impacto + Smear (`frames 2..3`, com **`impact_frame = 2`**):* avanço agressivo com abertura da jaqueta/roupa, extensão completa da arma presa exatamente no mesmo ponto da mão e rastro/smear em arquivo `vfx/` separado.
    - *Fase 3 — Recuperação (`frames 4..5`):* desaceleração pesada, dissipação do efeito em 1–2 frames e retorno à guarda. (`14 FPS`, no loop)
  - **Combate — `hurt` (4 frames):** golpe absorvido, recuo de tronco, dobra de joelho em dor, recomposição (`12 FPS`, no loop).
  - **Combate — `defeat` (6 frames):** cambaleio, queda aos joelhos, apoio no chão, desabamento completo mantendo **100% a mesma escala e proporções do personagem de pé** (`10 FPS`, no loop).
  - **Sem Combate / Estado Pacífico — `interact_*` (poses expressivas de 4–6 frames em loop/hold):**
    - `interact_talk` (gesticulação de fala consistente com o perfil), `interact_give` (estender/entregar ou receber item), `interact_point` (apontar direção/perigo), `interact_react` (sobressalto, súplica ou recuo defensivo), `interact_device` (segurar/examinar prancheta, rádio, manômetro, cesta ou vela).

### 1.3 Retratos Light Novel de Diálogo (`portraits/`)
- **Estilo:** Busto em traço forte de nanquim preto, hachuras marcadas nas sombras, alto contraste e clima psicológico sombrio fiel ao retrato canônico anexado de **Huwag**.
- **Protagonista (`Huwag`):** Preserva os 8 retratos já existentes no estilo nanquim (`assets/characters/portraits/huwag_casual_*.png` e `huwag_bfp_*.png`), **adicionando a expressão canônica anexada `sorriso_largo` (sorriso largo e levemente inquietante)** e variações ajustadas para o modo `dark`/sem filtro.
- **Personagens importantes da Fase 3:** Substituição completa dos antigos bustos pixelados `96 × 96` (`fnaf_*.png`) por novos bustos Light Novel em nanquim (`512 × 512` PNG RGBA transparente), com no mínimo **6 expressões por personagem importante**:
  `neutro`, `sorriso_largo`, `serio`, `surpreso`, `assustado` e `irritado` (+ variante `distorted` / `dark` para os confrontos da Dose Maior no Ato 2 e realidade sem filtro no Ato 3).

---

## 2. Lista Oficial dos Personagens da Fase 3 (Combate vs. Interação)

Inventário fechado de **14 personagens/entidades** conforme `scripts/autoload/game_state.gd`, `scripts/dialogue/character_profiles.gd` e mapas reconstruídos (`RoomHuwag`, `FireStation`, `StreetPreview`, `forest_trail`, `forest_clearing`), **incluindo Mang Carding e a reintrodução de Lola Rosa**:

| # | Personagem (e Apelido) | Papel / Cenas & Switches | Classificação (Combate vs. Interação) | Silhueta Única & Equipamento | Conjunto de Animações (`96×96`, 8 dir.) | Retratos Light Novel |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | **Huwag Matitiis** *("Anak", "Huwag")* | Protagonista jogável · Todos os mapas e switches (`001`–`026`) | **Combate + Interação** (Variantes **Casual Dia / Casual Dark** e **BFP Dia / BFP Dark**) | Cabelo loiro-palha arrepiado com raízes pretas, olheiras, fio no pescoço, jaqueta preta c/ capuz aberto (Casual) ou casaco BFP c/ faixas limpas sem capacete (BFP). Machado só no ataque. | `idle` (6f), `walk` (8f), `run` (8f), `attack` c/ machado BFP + `vfx` corte (6f, impacto `f2`), `hurt` (4f), `defeat` (6f) | 8 já existentes + **`sorriso_largo`** + **Dark** (`casual` e `bfp`) |
| 02 | **Capitão Reyes** *("Cap", "Chefe")* | Comandante do Quartel BFP · `FireStation`, rádio em `RoomHuwag` (`002`, `005`, `007`, `021`, `024`) | **Apenas Interação** *(Nunca entra em combate)* | Homem maduro largo de ombros, quepe estruturado de comandante com brasão, jaqueta longa abotoada com dragonas, bigode espesso, prancheta tática e rádio no cinto. | `idle` (6f), `walk` (8f), `interact_talk`, `interact_point`, `interact_give`, `interact_device` (prancheta/rádio), `interact_react` | 6 expressões + variante `dark/exaustão` |
| 03 | **Enfermeira Maria** *("Enfermeira", "Maria")* | Enfermaria BFP & Vigília · `FireStation`, `StreetPreview` | **Híbrido:** Interação por padrão / **Combate** se confrontada na Dose Maior (`conflict_choices`) | Mulher esguia em jaleco clínico acinturado sobre calça escura, coque baixo, franja dividida, bolsa médica transversal, prancheta de alumínio; versão hostil empunha prancheta cortante/bisturi com vfx sombrio. | **Normal:** `idle` (6f), `walk` (8f), `run` (8f), `interact_*` (prancheta/entrega/fala/reação). **Distorcida:** `idle`, `walk`, `run`, `attack` (6f + `vfx`), `hurt` (4f), `defeat` (6f) | 6 expressões + variante `distorted` |
| 04 | **Bombeiro Ato** *("Ato")* | Ala Oeste / Manutenção · `FireStation` | **Híbrido:** Interação por padrão / **Combate** se provocado na Dose Maior (`conflict_choices`) | Tronco largo e musculoso, **capacete BFP com lanterna frontal**, mangote enrolado no ombro e manômetro de latão na mão pacífica; **machado pesado BFP** fixo na versão hostil (capacete rachado/chamuscado). | **Normal:** `idle`, `walk`, `run`, `interact_*` (manômetro/mangueira). **Distorcida:** `idle`, `walk`, `run`, `attack` c/ machado (6f + `vfx`), `hurt` (4f), `defeat` (6f) | 6 expressões + variante `distorted` |
| 05 | **Bombeiro Santos** *("Santos")* | Descanso BFP & Ronda do Pátio · `FireStation`, `StreetPreview` | **Híbrido:** Interação por padrão / **Combate** no pátio sob Dose Maior (`NPC_Bombeiro_Ronda`) | Mais jovem e franzino, cabelo preto cacheado desordenado sem capacete, jaqueta BFP aberta sobre regata clara, rádio de ombro com antena longa; bastão de sinalização / barra de halligan curta na versão hostil. | **Normal:** `idle`, `walk`, `run`, `interact_*` (rádio/caneca/apontar). **Distorcida:** `idle`, `walk`, `run`, `attack` (6f + `vfx`), `hurt` (4f), `defeat` (6f) | 6 expressões + variante `distorted` |
| 06 | **Aling Nena** *("Tia Nena", "Nena")* | Dona da *Sari-Sari Store* · `StreetPreview` (**Missão Chave 2** `010`–`011`) | **Híbrido:** Interação / **Combate opcional** na Dose Maior (`conflict_choices`) | Silhueta materna baixa e encorpada, cabelo grisalho em coque com presilha vermelha grande, avental amplo com bolsos sobre vestido estampado, **vassoura de palha (*walis tingting*)** ou leque trançado. | **Normal:** `idle`, `walk`, `run`, `interact_*` (varrer/entregar sacola/apontar disjuntor/rezar). **Distorcida:** `idle`, `walk`, `run`, `attack` c/ vassoura/estaca (6f + `vfx`), `hurt`, `defeat` | 6 expressões + variante `distorted` |
| 07 | **Kuya Ben** *("Ben", "Kuya")* | Motorista de Jeepney & Mecânico · `StreetPreview` (**Missão Chave 1** `008`–`009`) | **Híbrido:** Interação / **Combate opcional** na Dose Maior (`conflict_choices`) | Estatura alta, boné de aba curva, **toalha branca dobrada no pescoço**, macacão de mecânico aberto na cintura com as mangas amarradas, pano sujo de graxa; **chave inglesa grande de aço** no combate hostil. | **Normal:** `idle`, `walk`, `run`, `interact_*` (ajustar peça/enxugar mão/apontar motor). **Distorcida:** `idle`, `walk`, `run`, `attack` c/ chave inglesa (6f + `vfx`), `hurt`, `defeat` | 6 expressões + variante `distorted` |
| 08 | **Mang Tomas** *("Feirante", "Tomas")* | Feirinha Leste do Barangay · `StreetPreview` (**Missão Chave 3** `012`–`013`) | **Híbrido:** Interação / **Combate opcional** na Dose Maior | Ombros curvados pelo peso, **chapéu cônico filipino (*salakot*) largo**, avental comprido de lona até a canela e botas de borracha; **cutelo largo de feira** fixo na versão distorcida. | **Normal:** `idle`, `walk`, `run`, `interact_*` (caixote/abano/*salakot*/apontar botijão). **Distorcida:** `idle`, `walk`, `run`, `attack` c/ cutelo (6f + `vfx`), `hurt`, `defeat` | 6 expressões + variante `distorted` |
| 09 | **Mang Carding** *("Carding")* | Pescador Veterano do Píer Oeste · `StreetPreview` (`NPC_Mang_Carding`, **Missão Chave 3** `013`) | **Híbrido:** Interação / **Combate opcional** na Dose Maior | Físico seco e fibroso, **bandana turquesa na testa**, camisa folgada amarrada na cintura, rede de pesca jogada sobre um ombro e **lamparina a querosene** na mão; **remo longo de madeira / croque** no estado hostil. | **Normal:** `idle`, `walk`, `run`, `interact_*` (erguer lamparina/puxar rede/apontar maré). **Distorcida:** `idle`, `walk`, `run`, `attack` c/ remo (6f + `vfx`), `hurt`, `defeat` | 6 expressões + variante `distorted` |
| 10 | **Toby** *("Toby")* | Garoto observador da rua · `StreetPreview` | **Apenas Interação + Corrida (`run`)** *(Jamais combate)* | Pré-adolescente bem menor (~44 px de altura), pernas finas, bermuda larga, **boné vermelho virado para trás**, camiseta listrada e **mochila escolar cheia nas costas**. | **Normal:** `idle`, `walk`, `run`, `interact_*` (apontar quartel/acenar/recuar assustado/contar nos dedos). **Distorcida:** tremor nervoso/contagem de dedos, sem ataque | 6 expressões (criança assustada/curiosa) |
| 11 | **Senhora Luningning** *("Lola Luningning")* | Recepção do Quartel & Vigília Leste · `FireStation`, `StreetPreview` (`014`–`019`) | **Híbrido:** Interação Central / **Combate Espectral** na Vigília Leste (`conflict_choices`) | Anciã esbelta um pouco arqueada, cabelo branco solto em coque fino, **xale lilás comprido balançando nos braços**, vestido longo até os tornozelos, **lanterna a óleo** e pose especial carregando o **gatinho alaranjado**. | **Normal:** `idle`, `walk`, `interact_*` (súplica/lanterna/falar/`interact_special` segurando o gatinho). **Distorcida:** `idle`, `walk`, `run`, `attack` espectral c/ lanterna carmesim (`vfx`), `hurt`, `defeat` | 6 expressões + variante `distorted` |
| 12 | **Lola Rosa** *("Lola Rosa", "Rosa")* | Vizinha Erborista do Quarteirão Oeste · `StreetPreview` (`NPC_Lola_Rosa`) | **Híbrido (Reintroduzida):** Interação / **Combate opcional** se agredida na Dose Maior | Anciã baixa de ombros estreitos, **lenço branco floral cobrindo os cabelos com trança grisalha lateral**, blusa creme tradicional *baro* folgada, saia longa verde-musgo e **cesta de palha com ramos de *lagundi*** no braço. | **Normal:** `idle`, `walk`, `run`, `interact_*` (oferecer erva/benzer/varrer/falar). **Distorcida:** `idle`, `walk`, `run`, `attack` sombrio de cinzas/ramos (`vfx`), `hurt`, `defeat` | 6 expressões + variante `distorted` |
| 13 | **Vulto Calcinado do Bosque** *("Vulto")* | Desfiladeiro da Mata (Ato 2 Dose Maior) · `forest_trail` (`NPC_Vulto_Bosque`) | **Interação Traumática + Combate Pesado** *(Alto dano / aceitação pacífica)* | Silhueta alongada e irregular (~64 px), capa/casaco BFP rasgado em tiras que ondulam como fuligem, capacete quebrado sem rosto, peito fendilhado em brasa viva, **machado longo carbonizado**. | `idle` fumegante (6f), `walk` pesado (8f), `run` investida (8f), `attack` golpe vertical/horizontal c/ brasa + `vfx` separado (6f, impacto `f2`), `hurt` (4f), `defeat` dissipação em cinzas (6f) | 4 expressões espectrais (neutro, sério/acusador, surpreso/cinza, irritado/brasa) |
| 14A | **Santelmo** *(`SantelmoEnemy`)* | 13 focos ígneos na `forest_trail` (Atos 1–2; ausentes no Ato 3) | **Combate Puro** | Espírito de fogo filipino em forma de chama alongada/orgânica sem corpo humano, núcleo branco-dourado, cauda sinuosa em chamas e olhos estreitos em brasa. | `idle` flutuante (6f), `walk` (8f), `run` investida ígnea (8f), `attack` bote de fogo + `vfx` labareda (6f, impacto `f2`), `hurt` (4f), `defeat` extinção em fumaça (6f) | *(Sem retratos — criatura instintiva)* |
| 14B | **Guardiã da Lagoa** *(`AquaticCreature`)* | Clareira da Lagoa · `forest_clearing` (`003`, `004`, `016`, `025`) | **Encontro de Dilema** (Conversar / Observar / Afastar / Combate) | Criatura anfíbia alta e graciosa, torso esguio coberto por escamas azul-petróleo, **barbatanas translúcidas alongadas nos antebraços e crista dorsal** reagindo à água, cauda sinuosa e olhos dourados. | `idle` ondulante (6f), `walk` deslize aquático (8f), `interact_talk` / `bless` (6f), `attack` jato/golpe de barbatana + `vfx` onda azul (6f, impacto `f2`), `hurt` (4f), `defeat` submersão (6f) | 6 expressões etéreas + reflexo sombrio (Dose Maior) |

---

## 3. Fichas Detalhadas de Personagem (Estilo Light Novel / Visual Novel)

### Ficha 01 — Huwag Matitiis *(Protagonista — "Anak" / "Huwag")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Huwag Matitiis** (chamado pelos mais velhos de **"Anak"** e pelos colegas de **"Huwag"**), 23 anos, bombeiro municipal do *Bureau of Fire Protection (BFP)* de Agdangan, Quezon. Protagonista jogável nos três atos, dividido entre a anestesia dos remédios e a culpa pelo incêndio do galpão onde perdeu três colegas.
- **Aparência (batendo com o sprite `96×96` e retrato anexado):**  
  Jovem filipino esguio e de postura relaxada (ombros ligeiramente soltos, cabeça levemente inclinada). Sua marca principal em todas as 8 direções é o **cabelo curto, arrepiado e desgrenhado em tom loiro-palha claro (`#EBE2A6` / `#D8CF92`) com mechas pontudas para vários lados e raízes/nuvens escuras (`#141218`)**. Pele morena quente (`#9E724D` com sombreado marcado), olhos escuros com **olheiras fundas bem visíveis** e **sorriso largo, confiante e levemente inquietante**.
  - **Traje Casual (Dia / Dark):** Jaqueta preta desgastada com gola alta/capuz aberto desenhada em **4 tons de grafite/cinza** nas dobras e costuras (jamais um bloco preto chapado), sobre camiseta preta, **fio fino escuro no pescoço**, calça cáqui-escura e tênis com solado claro. Na variante **Dark (Ato 3 Sem Filtro)**, a mesma roupa ganha paleta fria dessaturada e alto contraste de nanquim.
  - **Traje BFP (Dia / Dark):** Casaco azul-marinho operacional do BFP com **faixas refletivas limpas amarelo-ouro e laranja** (sem pontinhos ruidosos), mantendo o rosto com olheiras e o cabelo loiro-palha arrepiado descoberto (**sem capacete cobrindo a silhueta**).
  - **Postura de arma:** Mãos livres no `idle`/`walk`/`run`; no `attack` (fases 1–3), empunha sempre o **mesmo machado de bombeiro vermelho/aço**, com a mão presa exatamente no mesmo ponto do cabo e rastro de golpe em camada separada.
- **Personalidade (3 a 5 traços e um defeito):**  
  Tenaz, protetor com moradores humildes, observador atento de riscos elétricos e fumaça, corajoso sob perigo real e dotado de um humor tenso que mascara a exaustão.  
  *Defeito:* Esconde a culpa e o luto atrás de um sorriso largo forçado e do excesso de comprimidos, alternando obediência fria e explosões defensivas quando acuado.
- **Jeito de falar (tom, vocabulário, tiques, expressões típicas):**  
  Tom baixo, respeitoso com os mais velhos (*"Po"*, *"Entendido, Capitão"*), mas pontuado por tiradas secas ou um sorriso desconcertante quando tenta tranquilizar alguém mesmo estando à beira do colapso. Vocabulário prático de bombeiro (*turno, registro, fumaça, querosene, rebote*).
- **Objetivo e medo/segredo:**  
  *Objetivo:* Cumprir cada chamada em Agdangan e impedir que outro incêndio apague vidas no bairro.  
  *Medo/Segredo:* Teme ter travado o trinco da saída na noite do galpão e acredita que, se parar os comprimidos, não suportará encarar os três armários vazios do quartel.
- **Relação com o protagonista e com os outros personagens:**  
  Trata **Capitão Reyes** como pai adotivo; desvia o olhar dos exames da **Enfermeira Maria**; respeita os conselhos de ervas de **Lola Rosa**; age como irmão mais novo de **Kuya Ben**, **Aling Nena** e **Mang Carding** e herói próximo de **Toby**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Inclina levemente a cabeça com sorriso largo calmo (`idle` / postura relaxada).  
  - *Receber item / tarefa:* Abaixa os ombros, guarda o objeto/cápsula no bolso da jaqueta e acena firme.  
  - *Ignorado:* Permanece em vigília observando fiação e fumaça com respiração cadenciada (`idle` 6f).  
  - *Pressionado:* Sorriso fecha em expressão fria/tensa (`serio`/`irritado`) ou explode em movimento de combate (`attack` c/ machado, abas da jaqueta abrindo no avanço).
- **Frases-exemplo:**  
  1. *"Relaxa... a fumaça só parece grande antes de você achar onde ela começa."*  
  2. *"Tô inteiro, Enfermeira. Três horas de sono já seguram mais um plantão."*  
  3. *"Fica atrás de mim, pequeno. Esse cheiro de querosene já foi pior."*  
  4. *"Se não sobrou nenhum comprimido no frasco... pelo menos agora dá pra enxergar a rua do jeito que ela é."*
- **Mudança de atitude ao longo da fase:**  
  No **Ato 1**, sorri para disfarçar a insônia e cumpre ordens com docilidade. No **Ato 2 (Dose Normal)**, redescobre utilidade prática ajudando Kuya Ben, Aling Nena, Mang Tomas/Carding e salvando o gatinho; na **Dose Maior (`Intoxicacao >= 2`)**, a fachada sorridente trinca entre alucinações hostis e desespero. No **Ato 3 (Dark)**, caminha sem anestesia e aceita o luto com os companheiros na clareira.

---

### Ficha 02 — Capitão Reyes *(Apelido: "Cap" / "Chefe")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Capitão Reyes** (*"Cap"* / *"Chefe"*), 52 anos, Comandante do Destacamento BFP de Agdangan. Mentor operacional e guardião da verdade do galpão no Ato 3 (`002`, `005`, `007`, `021`, `024`). *(Apenas Interação — nunca combate.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Homem maduro de porte mais alto e ombros largos, bigode grisalho espesso, sobrancelhas carregadas, **quepe azul-marinho estruturado com viseira escura e brasão dourado**. Veste túnica de comando BFP mais comprida que a dos soldados (com dobras em 4 tons azul-grafite, dragonas nos ombros e cinto largo com rádio), calça tática reta e botas pesadas. Sem nenhuma arma.
- **Personalidade (3 a 5 traços e um defeito):**  
  Firme, paternal, disciplinado, paciente e atento aos limites psicológicos da tropa.  
  *Defeito:* Adia verdades dolorosas achando que está protegendo Huwag do choque, prolongando a dependência dos remédios.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Grave, cadenciado como boletim de rádio (*"Positivo"*, *"Câmbio"*, *"Anak"*), limpando a garganta antes de revelar fatos difíceis.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Manter Agdangan segura e guiar Huwag de volta à lucidez sem perdê-lo para o remorso.  
  *Medo/Segredo:* Carrega culpa silenciosa por ter assinado a escala daquela madrugada no galpão e teme não conseguir segurar o rapaz quando os frascos acabarem.
- **Relação com o protagonista e com os outros personagens:**  
  Vê **Huwag** como filho; confia em **Enfermeira Maria** nos limites clínicos e coordena **Bombeiro Ato** e **Bombeiro Santos**, sendo referência moral para **Aling Nena**, **Kuya Ben**, **Lola Rosa** e **Senhora Luningning**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Ergue o rosto do mapa e gesticula com a palma aberta (`interact_talk`).  
  - *Receber relatório / concluir missão (`021`):* Estende a recompensa (`gota_calmante`) com ambas as mãos firmes (`interact_give`).  
  - *Ignorado:* Examina a **prancheta/rádio** imóvel na mesa de comando (`interact_device`).  
  - *Pressionado (Dose Maior):* Aponta com firmeza solene para os pinos no mapa (`interact_point`), mantendo voz baixa e postura inabalável.
- **Frases-exemplo:**  
  1. *"Bom dia, anak. Está seguindo a dose certa antes de sair para a ronda?"*  
  2. *"Dezoito meses e aqueles três pinos continuam no mesmo galpão no mapa."*  
  3. *"As criaturas na mata só existem onde você ainda se recusa a olhar de frente."*  
  4. *"Chegou a hora de tirar o filtro, Huwag. Você sobreviveu — e não foi por covardia."*
- **Mudança de atitude ao longo da fase:**  
  Protocolar e protetor no **Ato 1**; preocupado e firme no **Ato 2** (especialmente se notar `Intoxicacao >= 2`); completamente franco e humano no **Ato 3**, encerrando os segredos no escritório (`024_Ato3_revelacao_reyes`).

---

### Ficha 03 — Enfermeira Maria *(Apelido: "Maria" / "Enfermeira")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Enfermeira Maria**, 29 anos, Enfermeira de Saúde Ocupacional na ala leste do Quartel BFP. Controla os prontuários e a dosagem máxima (`3 comprimidos/dia`), atuando como espelho clínico na Dose Maior. *(Híbrido: Interação por padrão / Combate opcional se confrontada via `conflict_choices`.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Silhueta esguia e ereta bem distinta dos bombeiros: cabelo preto longo preso em **coque baixo elegante com duas mechas soltas**, jaleco clínico acinturado azul-acinzentado com gola dobrada (cujos faldões balançam ao caminhar), **bolsa de primeiros socorros pendurada em alça transversal**, calça azul-marinho e sapatos fechados. Segura **prancheta metálica branca** nas poses pacíficas; na forma distorcida avança com roupas manchadas em carmesim e **bisturi/prancheta cortante** em ataque direcional.
- **Personalidade (3 a 5 traços e um defeito):**  
  Meticulosa, lúcida, empática na escuta clínica, corajosa para dizer verdades incômodas.  
  *Defeito:* Rigidez fria quando um paciente mente sobre dosagem ou esconde sintomas visíveis.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Dicção limpa e calma de triagem médica; vocabulário clínico cotidiano (*"sinais vitais"*, *"rebote"*, *"pupila"*, *"limite seguro"*), olhando alternadamente da prancheta para as olheiras de Huwag.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Evitar uma crise dissociativa aguda antes que o corpo de Huwag ceda à exaustão.  
  *Medo/Segredo:* Guardou as folhas rasuradas do prontuário original fora do relatório oficial para que não afastassem Huwag do serviço, e teme ter prolongado o dano.
- **Relação com o protagonista e com os outros personagens:**  
  Monitora **Huwag**, **Ato** e **Santos**; discorda em voz baixa do **Capitão Reyes** sobre quanto tempo o silêncio ainda protege; troca infusões calmantes com **Lola Rosa**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Segura a prancheta contra o peito e fala avaliando o interlocutor (`interact_talk` / `interact_device`).  
  - *Receber retorno clínico:* Estende receita/água com gesto preciso (`interact_give`) ou assinala na prancheta (`interact_device`).  
  - *Ignorado:* Vira a página da ficha anotando o horário (`idle` com respiração + `interact_device`).  
  - *Pressionado (Dose Maior):* Recua em choque clínico (`interact_react`) e, caso Huwag a acuse agressivamente, transforma-se e desfere corte clínico rápido (`attack` 6f + `vfx` separado).
- **Frases-exemplo:**  
  1. *"Suas olheiras pioraram hoje, Huwag. Não passe de três comprimidos — o rebote já está distorcendo a rua."*  
  2. *"Tem cheiro forte de fumaça vindo da saída leste desde cedo."*  
  3. *"Vai riscar os nomes deste prontuário mais quantas vezes até aceitar que eram reais?"*  
  4. *"Sem anestesia dói mais, eu sei. Mas hoje você finalmente está olhando nos meus olhos."*
- **Mudança de atitude ao longo da fase:**  
  Cuidadosa e firme no **Ato 1** e **Ato 2 normal**; severa e acusatória sob **Dose Maior** (cessando se Huwag reconhece os colegas mortos, ou atacando se ele nega em fúria); respeitosa e aliviada no **Ato 3**.

---

### Ficha 04 — Bombeiro Ato *(Apelido: "Ato")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Bombeiro Ato**, 26 anos, Operador de Bombas e Mangueiras na ala oeste do Quartel. Representa a técnica do galpão e, na **Dose Maior**, confronta Huwag sobre o **trinco fechado na porta**. *(Híbrido: Interação / Combate opcional se provocado via `conflict_choices`.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Silhueta larga e musculosa (ombros mais amplos do quartel), **capacete BFP amarelo-âmbar arredondado com aba traseira longa e lanterna frontal** (que deixa o maxilar forte à mostra), jaqueta azul-marinho BFP com **duas faixas refletivas laranja/ouro contínuas e largas**, **mangote preto enrolado no ombro direito**, botas pesadas de combate a incêndio. Segura **manômetro de pressão / bico de mangueira** nas interações; na forma distorcida, o capacete surge queimado de fuligem com visor rachado e empunha o **machado pesado BFP** fixo na mão.
- **Personalidade (3 a 5 traços e um defeito):**  
  Prático, leal, obsessivo por checagem de equipamentos, franco sem rodeios.  
  *Defeito:* Pouca paciência com descuido ou respostas evasivas perto de ferramentas e válvulas.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Direto, voz cheia de garagem/oficina (*"Bora revisar"*, *"Tô na pressão"*), vocabulário mecânico (*válvula, registro, engate, trinco, viga*).
- **Objetivo e medo/segredo:**  
  *Objetivo:* Deixar mangueiras, bombas e travas 100% operacionais para que nenhuma sirene falhe em serviço.  
  *Medo/Segredo:* Desde que viu três armários trancados após o acidente, confere duas vezes cada fecho com medo de travar alguém lá dentro.
- **Relação com o protagonista e com os outros personagens:**  
  Colega próximo de **Santos** no pátio e parceiro de ferramentas de **Kuya Ben**; respeita **Huwag**, mas nota quando o amigo hesita diante do machado.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Abaixa o manômetro e explica o estado das bombas (`interact_talk` / `interact_device`).  
  - *Receber item / peça de engate:* Confere o peso na hora (`interact_device`) e aponta o caminhão pronto (`interact_point`).  
  - *Ignorado:* Segue ajustando a mangueira com respiração pesada (`idle` / `interact_device`).  
  - *Pressionado (Dose Maior):* Aponta o dedo acusador pelo trinco da porta (`interact_point`) e, diante da negação violenta, ergue e golpeia com o machado pesado (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Tô conferindo a pressão aqui na ala oeste. O caminhão lá fora também pede olho no engate."*  
  2. *"Por que a barra do trinco estava fechada por fora quando a viga desabou sobre a gente, Huwag?"*  
  3. *"Pressão baixa mata em silêncio — não espera ninguém lembrar depois."*  
  4. *"A viatura tá pronta quando você estiver pronto pra encerrar o turno, irmão."*
- **Mudança de atitude ao longo da fase:**  
  Companheiro de turno no **Ato 1** e **Ato 2 normal**; sombrio e insistente na **Dose Maior**; silenciosamente solidário na oficina cinzenta do **Ato 3**.

---

### Ficha 05 — Bombeiro Santos *(Apelido: "Santos")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Bombeiro Santos**, 24 anos, Guarda de Prontidão (Ala Oeste do Quartel e Ronda no Pátio de `StreetPreview`). Companheiro mais próximo da idade de Huwag e elo com as vagas deixadas pelos mortos. *(Híbrido: Interação / Combate opcional em `NPC_Bombeiro_Ronda` sob Dose Maior.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Jovem magro e ágil (silhueta esguia contrastando com Ato e Reyes), **cabelo preto cacheado curto volumoso** (sem capacete para contrastar silhueta e cor com Huwag), jaqueta BFP aberta mostrando camiseta branca interna, **faixa refletiva fina única** e **rádio transmissor no ombro com antena longa** balançando no movimento. Gesticula com rádio ou caneca nas interações; na forma distorcida carmesim ataca com **barra halligan / bastão metálico**.
- **Personalidade (3 a 5 traços e um defeito):**  
  Fraterno, atento aos sinais de fadiga dos amigos, calmo de dia, ansioso nas rondas da madrugada.  
  *Defeito:* Guarda a própria apreensão atrás de conversas leves até explodir emocionalmente no limite.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Gíria fraterna urbana filipina (*"Bro"*, *"Beleza?"*), frases curtas; na distorção murmura contagens repetidas (*"três pares..."*).
- **Objetivo e medo/segredo:**  
  *Objetivo:* Cobrir o portão da frente e impedir que Huwag desabe de exaustão em serviço.  
  *Medo/Segredo:* Sabe que só ganhou vaga porque três bombeiros morreram naquele turno — e teme perder o único colega com quem divide a rotina noturna.
- **Relação com o protagonista e com os outros personagens:**  
  Amigo de folga de **Huwag**, colega de ala de **Ato**, paciente dócil da **Enfermeira Maria** e conhecido da feira por **Toby** e **Aling Nena**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Ergue o braço livre em saudação aberta e ajusta o rádio do ombro (`interact_talk` / `interact_device`).  
  - *Receber aviso / café:* Aceita com sorriso aliviado (`interact_give`) e aponta o portão (`interact_point`).  
  - *Ignorado:* Patrulha em passo calmo (`walk` 8f) vigiando a entrada do quartel.  
  - *Pressionado (Dose Maior):* Recua tenso (`interact_react`) repetindo os três pares vazios de luvas; se Huwag o expulsar aos gritos, avança em combate no pátio (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Bro, olha o estado dessas olheiras... Toma um copo d'água antes de atravessar o portão."*  
  2. *"Contou quantos pares de luvas sobram na fileira? Ficam sempre três esperando alguém voltar."*  
  3. *"Você também ouviu a sirene tocar antes do caminhão ligar?"*  
  4. *"O Capitão Reyes tá esperando na sala de comando, Huwag. Hoje ele vai abrir todo o relatório."*
- **Mudança de atitude ao longo da fase:**  
  Leal e fraterno nos **Atos 1 e 2 normais**; sombrio e assombrado na **Dose Maior**; aliviado ao encaminhar Huwag ao encontro definitivo com o Capitão no **Ato 3**.

---

### Ficha 06 — Aling Nena *(Apelido: "Tia Nena" / "Nena")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Aling Nena**, 58 anos, comerciante da pequena *Sari-Sari Store* na Rua Principal de Agdangan. Protagoniza a **Missão Chave 2 (`010`–`011`)**: curto-circuito no freezer soltando faíscas na fachada de madeira. *(Híbrido: Interação / Combate opcional se agredida na Dose Maior.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Senhora de estatura baixa e porte materno arredondado, cabelos escuros grisalhos em **coque volumoso preso com presilha vermelha bem visível**, **avental largo azul-ardósia com bolso dianteiro** amarrado sobre vestido bordô e **vassoura rústica de palha (*walis*) / leque trançado** que balança nas interações. Na variante distorcida, a presilha escurece, o rosto fica em sombra funda e ataca com golpes rápidos de vassoura/cabo quebrado.
- **Personalidade (3 a 5 traços e um defeito):**  
  Calorosa, trabalhadora, comunicativa, protetora com o quarteirão.  
  *Defeito:* Apreensiva em excesso com pane elétrica e escuridão desde a noite em que a rua inteira ficou sem luz durante o incêndio do galpão.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Emotivo e caseiro; usa tagalo cotidiano natural (**"Naku!"**, **"Salamat!"**), chamando Huwag pelo nome com carinho ou apavorada diante das faíscas.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Salvar a *Sari-Sari Store* de pegar fogo e manter a vizinhança unida apesar dos dias vazios.  
  *Medo/Segredo:* Carrega a dúvida não dita de quem desligou o quadro de energia na madrugada do acidente antes do desabamento.
- **Relação com o protagonista e com os outros personagens:**  
  Viu **Huwag** crescer na rua; conversa com **Lola Rosa** sobre compras e insônia, vende gelo para **Mang Carding** e **Kuya Ben**, e dá doces a **Toby**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Segura o leque/avental explicando o perigo com gestos expressivos (`interact_talk`).  
  - *Ao receber ajuda (`011` — disjuntor salvo):* Junta as palmas em agradecimento e entrega suprimento (`interact_give`).  
  - *Ignorado:* Varre inquieta a entrada da loja (`walk` / `interact_device`) olhando para o poste.  
  - *Pressionado (Dose Maior):* Aponta o quadro elétrico acusando Huwag pelo apagão (`interact_point` -> `interact_react`); se ofendida com violência, parte para ataque rápido (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Huwag! O fio do freezer tá soltando faísca bem na tábua seca da parede!"*  
  2. *"Naku, salamat! Salvou minha vendinha! Passa lá no quartel falar com o Capitão Reyes!"*  
  3. *"A luz caiu na rua toda antes de o telhado desabar... Você fechou a chave geral ou fechou os olhos?"*  
  4. *"A cidade toda sabe o que você tentou naquele galpão, filho. Pare de engolir essas pílulas pra se castigar."*
- **Mudança de atitude ao longo da fase:**  
  Acolhedora no **Ato 1**; desesperada e grata no **Ato 2 normal**; acusadora (ou combatente se provocada) sob **Dose Maior**; maternal e terna no **Ato 3**, pedindo que Huwag não se destrua mais com comprimidos.

---

### Ficha 07 — Kuya Ben *(Apelido: "Ben" / "Kuya")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Kuya Ben**, 41 anos, motorista de Jeepney / triciclo e mecânico da rua principal. Protagoniza a **Missão Chave 1 (`008`–`009`)**: motor superaquecido vazando óleo perto da karinderya. *(Híbrido: Interação / Combate opcional se confrontado na Dose Maior.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Homem alto e largo de costas fortes, **boné azul-acinzentado com aba visível**, bigode marcado, **toalha branca dobrada pendurada ao redor do pescoço** (pontas soltas acompanhando o movimento), regata clara por baixo de **macacão azul de mecânico dobrado na cintura** (com as mangas amarradas no quadril) e botas gastas. Limpa as mãos com pano nas interações; na forma distorcida empunha **chave inglesa pesada** de tamanho fixo.
- **Personalidade (3 a 5 traços e um defeito):**  
  Prático, direto, protetor como irmão mais velho, atento a ruídos de motor e cheiro de óleo.  
  *Defeito:* Teimoso e ressentido quando suspeita que alguém falhou em abrir caminho para os veículos na emergência.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Franco e camarada (*"Valeu, irmão!"*, *"Escuta aqui..."*), termos de oficina (*registro, óleo, buzina, engate, travessa*).
- **Objetivo e medo/segredo:**  
  *Objetivo:* Manter o transporte rodando para escoar suprimentos e evacuar moradores se o fogo avançar.  
  *Medo/Segredo:* Ainda escuta em pesadelos a buzina de quem ficou preso na travessa bloqueada pelos escombros na noite do galpão.
- **Relação com o protagonista e com os outros personagens:**  
  Trata **Huwag** como irmão; trabalha junto com **Bombeiro Ato** na manutenção, abastece a loja de **Aling Nena** e transporta gelo para **Mang Carding** e **Mang Tomas**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Apoia as mãos na cintura e fala com franqueza (`interact_talk`).  
  - *Ao receber ajuda (`009` — óleo contido):* Bate no ombro em gesto de apoio e aponta o quartel (`interact_give` / `interact_point`).  
  - *Ignorado:* Volta a examinar o motor soltando vapor (`interact_device`).  
  - *Pressionado (Dose Maior):* Recua em tensão (`interact_react`) cobrando por que o caminhão parou na travessa; se chamado de mentiroso, golpeia com a chave inglesa pesada (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Huwag! Esse motor ferveu e tá pingando óleo quente no asfalto! Fecha o registro comigo!"*  
  2. *"Valeu mesmo, irmão! Passa lá no Capitão Reyes pra pegar seu suprimento!"*  
  3. *"A buzina tocou três vezes no meio da fumaça... Por que teu caminhão não abriu a travessa?"*  
  4. *"Vai lá dentro falar com o Reyes, Huwag. Encerra essa madrugada em paz."*
- **Mudança de atitude ao longo da fase:**  
  Aliado firme no **Ato 1** e **Ato 2 normal**; voz dura de cobrança na **Dose Maior**; o primeiro vizinho a enxergar serenidade no passo sóbrio de Huwag no **Ato 3**.

---

### Ficha 08 — Mang Tomas *(Apelido: "Feirante" / "Tomas")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Mang Tomas** (creditado na UI como **"Feirante do Barangay"**), 47 anos, comerciante da feira próxima à entrada leste da floresta. Protagoniza a **Missão Chave 3 — setor leste (`012`–`013`)**: vazamento de gás próximo ao fogareiro aceso. *(Híbrido: Interação / Combate opcional na Dose Maior.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Silhueta inconfundível pelo **chapéu cônico tradicional de palha (*salakot*) largo e pontiagudo** (com alça sob o queixo), postura levemente curvada de quem carrega caixotes, camisa bege de linho arregaçada, **avental longo de lona verde-oliva** até os tornozelos e tamancos/botas de feira. Segura **caixote de feira / abano** nas interações; na variante distorcida o *salakot* surge lascado e ataca com **cutelo curto de feira**.
- **Personalidade (3 a 5 traços e um defeito):**  
  Observador do vento, cauteloso, trabalhador disciplinado, resiliente.  
  *Defeito:* Desconfiado e arredio ao entardecer; fecha a banca na pressa para não ver o que se move além do último poste.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Voz seca de vendedor de rua (*"Bombeiro!"*, *"Bombeiro Huwag!"*), frases diretas sempre checando direção do vento e cheiro de gás.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Evitar uma explosão de gás nas casas de madeira e sustentar as poucas bancas ativas da feira leste.  
  *Medo/Segredo:* Foi quem viu as primeiras labaredas subirem da borda da mata naquela noite antiga — e ainda teme que o fogo desça outra vez até as barracas.
- **Relação com o protagonista e com os outros personagens:**  
  Confia no ofício de **Huwag** e nas rondas do **Capitão Reyes**; compra pescado de **Mang Carding** e espanta **Toby** quando o garoto se aproxima demais da mata.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Segura a aba do *salakot* e conversa alerta (`interact_talk`).  
  - *Ao receber ajuda (`013` — gás fechado):* Abaixa a guarda, entrega agradecimento (`interact_give`) e aponta o quartel (`interact_point`).  
  - *Ignorado:* Empilha caixotes fechando a banca (`interact_device`).  
  - *Pressionado (Dose Maior):* Recua agitado (`interact_react`) e, caso seja agredido no diálogo, avança com o cutelo em arco (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Bombeiro Huwag! O botijão tá vazando do lado da brasa do fogareiro! Ajuda a fechar e ventilar isso!"*  
  2. *"Obrigado, bombeiro! O Capitão pediu pra você retornar assim que terminar na rua."*  
  3. *"Quase todo mundo fechou cedo hoje. Ninguém fica tranquilo perto da mata depois que escurece."*  
  4. *"Todo mundo viu você seguir de pé mesmo quando faltou ar naquela rua."*
- **Mudança de atitude ao longo da fase:**  
  Arisco no **Ato 1**; agradecido no **Ato 2 normal**; hostilizável sob a alucinação vermelha da **Dose Maior**; respeitoso e calmo na **Ato 3**.

---

### Ficha 09 — Mang Carding *(Apelido: "Carding" / "Tio Carding")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Mang Carding**, 54 anos, pescador veterano do píer oeste de Agdangan (`NPC_Mang_Carding` / `Cais_Praia`). Cuida do barco de madeira e redes secas; participa da urgência comunitária da **Missão Chave 3 (`013_Missao_chave3_concluida`)** quando uma lamparina tomba sobre as redes e ancora o epílogo costeiro do **Ato 3**. *(Híbrido: Interação / Combate opcional se provocado na Dose Maior.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Homem maduro magro e fibroso, pele bem queimada de sol, **bandana azul-turquesa amarrada na testa com pontas soltas atrás da cabeça**, camisa aberta azul-petróleo desbotada com mangas arregaçadas, **rede de pesca enrolada em diagonal sobre o ombro**, calça dobrada na canela e sandálias de corda. Segura **lamparina a querosene acesa** nas poses de interação; na forma distorcida usa **remo comprido de madeira** como arma fixa de alcance.
- **Personalidade (3 a 5 traços e um defeito):**  
  Sereno, experiente com ventos e marés, solidário, melancólico sem drama.  
  *Defeito:* Fatalista diante da perda — acredita que o mar e a memória sempre trazem de volta o que a gente tenta enterrar.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Pausado e rouco de beira de cais (*"Bombeiro!"*, *"Salamat po!"*), usando imagens de maré, sal, vento sul e rede seca.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Preservar o barco e as redes que mantêm famílias inteiras no extremo oeste do bairro.  
  *Medo/Segredo:* Na noite do desabamento do galpão, viu a claridade laranja refletida na água preta da baía e nunca esqueceu a sirene ecoando sem parar.
- **Relação com o protagonista e com os outros personagens:**  
  Conhece **Huwag** desde menino; fornece peixe para **Mang Tomas**, conversa com **Aling Nena** e reza pela equipe junto a **Lola Rosa**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Ergue a lamparina iluminando o rosto e fala baixo (`interact_device` / `interact_talk`).  
  - *Ao apagar fogo nas redes (`013`):* Estende ambas as mãos em respeito (*"Salamat po!"*, `interact_give`) e aponta o barco salvo (`interact_point`).  
  - *Ignorado:* Puxa o nó da rede olhando para o mar escuro (`idle` 6f).  
  - *Pressionado (Dose Maior):* Recua tenso sob o reflexo vermelho (`interact_react`) e, se afrontado, desfere varredura ampla com o remo (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Bombeiro! A lamparina tombou em cima das redes secas no píer! Se pegar no casco do barco a gente perde tudo!"*  
  2. *"Salamat po! Você segurou o fogo antes de virar cinza na madeira."*  
  3. *"Mesmo aqui no cais o vento sul ainda traz cheiro de querosene até a maré."*  
  4. *"A água leva a fuligem do cais, Huwag... mas o que ficou na memória precisa de você com os olhos abertos."*
- **Mudança de atitude ao longo da fase:**  
  Contemplativo no **Ato 1**; aflito e profundamente grato no **Ato 2 normal**; sombrio na **Dose Maior**; acolhedor à beira-mar no **Ato 3**.

---

### Ficha 10 — Toby *(Apelido: "Toby")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Toby**, 10 anos, garoto curioso do bairro. Atua como **informante inocente** na rua principal: conta sobre as luzes na floresta no Ato 1 e avisa que viu a Senhora Luningning correr ao quartel atrás do gatinho no Ato 2. *(Apenas Interação + Corrida — jamais entra em combate.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Claramente menor que os adultos (~44 px de altura com pés em `y = 82` para leitura imediata de escala infantil), postura inquieta, **boné vermelho grande virado para trás**, camiseta amarelo-mostarda larga com listra naval, short jeans comprido, tênis grandes e **mochila escolar azul redonda nas costas** visível nas 8 direções (balançando na corrida). Sem armas.
- **Personalidade (3 a 5 traços e um defeito):**  
  Curioso, energético, observador literal, carinhoso com os bombeiros.  
  *Defeito:* Repete sem filtro segredos que ouviu dos adultos fecharem a porta, ferindo sem querer quem tenta esquecer.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Rápido e cheio de exclamações (**"Ei, tio Huwag!"**); sob **Dose Maior**, perde o entusiasmo e sussurra contagens nos dedos.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Descobrir o que brilha além do último poste e ajudar o tio bombeiro a salvar o gato perdido.  
  *Medo/Segredo:* Percebeu que todos os adultos contam nos dedos quantos capacetes restaram no quartel e abaixam as cortinas quando o caminhão passa.
- **Relação com o protagonista e com os outros personagens:**  
  Idolatra **Huwag** como irmão herói; ganha balas de **Aling Nena**, passa por **Lola Rosa**, observa a banca de **Mang Tomas** e seguiu os passos apressados de **Senhora Luningning**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Freia a corridinha e acena animado (`interact_talk`).  
  - *Receber orientação:* Acena concordando e aponta rapidamente a saída para o quartel ou mata (`interact_point`).  
  - *Ignorado:* Volta a correr de um lado a outro na calçada (`run` 8f).  
  - *Pressionado (Dose Maior):* Recua encolhendo os ombros perto da mochila (`interact_react`) e levanta os dedos em contagem muda (`interact_device`). Sem combate.
- **Frases-exemplo:**  
  1. *"Ei, tio Huwag! Vi uma senhora correndo pro quartel dizendo que o gatinho fugiu lá pra mata!"*  
  2. *"De noite dá pra ver clarões andando sozinhos depois do último poste..."*  
  3. *"Os adultos fecham as cortinas quando o caminhão passa... e contam nos dedos quantos capacetes ficaram no galpão."*
- **Mudança de atitude ao longo da fase:**  
  Cheio de energia nos **Atos 1 e 2 normais**; encolhido e pálido sob **Dose Maior**; aliviado ao ver Huwag andando em paz na luz cinzenta do **Ato 3**.

---

### Ficha 11 — Senhora Luningning *(Apelido: "Lola Luningning")*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Senhora Luningning**, 68 anos, moradora solitária. É o **gatilho narrativo central da segunda metade do Ato 2** (`014`–`019`): na recepção do Quartel suplica pelo resgate de seu gatinho na floresta em chamas; sob **Dose Maior**, aparece também na **Vigília Leste (`NPC_Vigilia_Leste`)** junto ao asfalto rachado. *(Híbrido: Interação / Combate Espectral se confrontada na Vigília Leste.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Anciã esbelta com leve arqueamento nas costas, **cabelo branco-prateado preso em coque tradicional**, **xale lilás comprido (`#6D4C7D`) com franjas flutuantes** sobre os ombros, vestido longo até os sapatos baixos e **lanterna metálica acesa** na mão. Na pose especial `interact_special`, segura nos braços o **gatinho alaranjado resgatado**. Na variante distorcida/espectral, o xale se alonga em tiras escuras avermelhadas e a lanterna projeta faíscas espectrais vermelhas (`attack` + `vfx`).
- **Personalidade (3 a 5 traços e um defeito):**  
  Doce, corajosa apesar da fragilidade física, grata, solitária e resiliente.  
  *Defeito:* Movida pelo medo de perder o único ser vivo em sua casa, atravessa fumaça e distância sozinha ignorando a própria saúde.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Voz trêmula, mansa e cortês (*"Salamat po, Huwag!"*, *"Bombeiro Huwag!"*); na vigília distorcida ganha tom solene de lamento.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Recuperar seu gatinho antes que as chamas alcancem a clareira.  
  *Medo/Segredo:* Ficar completamente sozinha dentro da casa vazia — espelho direto da solidão de Huwag após o incêndio do galpão.
- **Relação com o protagonista e com os outros personagens:**  
  Confia a **Huwag** e ao **Capitão Reyes** seu último pedido; cruzou com **Toby** na avenida e compartilha preces silenciosas com **Lola Rosa**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Ergue a lanterna e junta as mãos suplicando (`interact_talk` / `interact_react`).  
  - *Receber o gatinho resgatado (`017 -> 018`):* Acolhe o gatinho no colo junto ao xale (`interact_special` / `interact_give`) emocionada.  
  - *Ignorado:* Aguarda imóvel no banco com xale tremendo levemente (`idle` 6f).  
  - *Pressionado (Vigília Leste sob Dose Maior):* Aponta a mata ardendo (`interact_point`); se Huwag negar com fúria, libera ataque espectral com luz carmesim (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Tô esperando o Capitão liberar o chamado... Já dá pra sentir fumaça subindo lá do leste."*  
  2. *"Bombeiro Huwag! O fogo subiu pela trilha e meu gatinho fugiu direto pra clareira!"*  
  3. *"Salamat po, Huwag! Ele tá vivo no meu colo graças a você."*  
  4. *"Você engoliu mais comprimidos pra calar a rua... mas eles ainda estão esperando dentro da mata."*
- **Mudança de atitude ao longo da fase:**  
  Suplicante no **Ato 2** até Huwag abrir o chamado; profundamente grata ao receber o gatinho (encerrando o Ato 2); ausente no banco frio do **Ato 3**, onde restam apenas cinzas sobre a madeira.

---

### Ficha 12 — Lola Rosa *(Apelido: "Lola Rosa" / "Vó Rosa" — Reintroduzida)*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Lola Rosa**, 71 anos, vizinha idosa e erborista de quintal no quarteirão oeste (`NPC_Lola_Rosa`, reintroduzida de `character_profiles.gd`). Escuta a insônia noturna de Huwag perto da quitinete nos Atos 1 e 2, oferece chá de *lagundi* contra a fumaça e, na **Dose Maior**, questiona o quarto fechado à chave. *(Híbrido: Interação / Combate opcional se agredida na Dose Maior.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Claramente distinta da Senhora Luningning na silhueta e paleta: estatura mais baixa e firme, **lenço branco floral amarrado na cabeça** sobre **trança grisalha grossa caída sobre um ombro**, blusa creme tradicional *baro* de mangas folgadas, **saia longa estampada em verde-musgo e bordô**, e **cesta rústica de palha com ramos verdes de *lagundi*** pendurada no antebraço esquerdo. Na versão distorcida, o lenço desliza ensombrando os olhos e a cesta solta cinzas em brasa no ataque.
- **Personalidade (3 a 5 traços e um defeito):**  
  Maternal, atenta aos detalhes domésticos, gentil, teimosa nos cuidados tradicionais, protetora.  
  *Defeito:* Insiste demais com conselhos de chás e bênçãos mesmo quando o jovem só precisa respirar sem ser observado.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Manso e rítmico de avó filipina (**"Susmaryosep..."**, **"Anak..."**), reparando nas olheiras e no cheiro de cinza nas mangas de Huwag.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Cuidar da saúde simples do quarteirão oeste para que ninguém adoeça de tristeza sozinho.  
  *Medo/Segredo:* Sabe que folha nenhuma cura pesadelo químico e teme ouvir outro toque de ambulância ou sirene na porta ao lado da sua.
- **Relação com o protagonista e com os outros personagens:**  
  Vizinha imediata de **Huwag**; troca receitas com **Enfermeira Maria**, faz feira com **Aling Nena** e **Mang Carding** e reza junto de **Senhora Luningning**.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Segura a alça da cesta e olha com carinho cansado (`interact_talk`).  
  - *Ao entregar folhas de lagundi / bênção:* Oferece ramo verde da cesta com ambas as mãos (`interact_give`).  
  - *Ignorado:* Segue ajeitando as folhas ou varrendo a soleira oeste (`walk` / `interact_device`).  
  - *Pressionado (Dose Maior):* Recua ferida (`interact_react`) perguntando por que ele tranca todas as janelas; se repelida com brutalidade, transforma-se e lança rajada de cinzas/ramos (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"Susmaryosep, Huwag... Ouvi seus passos andando no quarto a madrugada inteira outra vez."*  
  2. *"Peguei folhas frescas de lagundi pra tosse da fumaça — não viva só desses frascos brancos, anak."*  
  3. *"Por que você tranca a janela tão forte? Tem medo do vento entrar ou do silêncio responder?"*  
  4. *"Vá firme hoje sem abaixar a cabeça. O quarteirão inteiro reza pelo seu retorno."*
- **Mudança de atitude ao longo da fase:**  
  Acolhedora no **Ato 1** e **Ato 2 normal**; sufocante e insistente na **Dose Maior**; serena e orgulhosa ao enxergar Huwag de cabeça erguida no **Ato 3**.

---

### Ficha 13 — Vulto Calcinado do Bosque *(Apelido: "Vulto" / `NPC_Vulto_Bosque`)*

- **Nome (e apelido), idade, ocupação e papel na história:**  
  **Vulto Calcinado do Bosque** (*"Os Três"*), entidade traumática sem idade que materializa os três colegas perdidos no galpão. Bloqueia o trecho final de `forest_trail` exclusivamente sob **Dose Maior (`Intoxicacao >= 2`)**. *(Interação Traumática + Combate Pesado se confrontado com negação.)*
- **Aparência (batendo com o sprite `96×96`):**  
  Silhueta alta e esfiapada (~64 px), casaco BFP **carbonizado em cinza-carvão com tiras rasgadas que flutuam como fumaça**, **capacete rachado sem rosto deixando duas fendas incandescentes no escuro**, peito aberto com **brasas carmesins pulsando**, empunhando **machado grande enegrecido em brasa** preso firmemente à mão em todo ciclo de ataque (`vfx` separado de fuligem e corte ígneo).
- **Personalidade (3 a 5 traços e um defeito):**  
  Solene, imóvel até ser interpelado, implacável como fumaça densa, espelho direto do remorso.  
  *Defeito:* Incapaz de meio-termo — só conhece dissipar-se diante do reconhecimento verdadeiro ou golpear sem piedade diante da negação.
- **Jeito de falar (tom, tiques, expressões típicas):**  
  Voz grave e estalada como madeira queimando, repetindo termos de *querosene, papel queimado e fogo seu*.
- **Objetivo e medo/segredo:**  
  *Objetivo:* Impedir Huwag de correr até a clareira fingindo que nunca houve perda real atrás dos monstros.  
  *Medo/Segredo:* Desfaz-se no instante em que Huwag pára de negar e reconhece os mortos com humanidade.
- **Relação com o protagonista e com os outros personagens:**  
  Condensa a dor lembrada por **Capitão Reyes**, **Enfermeira Maria**, **Ato**, **Santos** e **Toby** sempre que mencionam o número três.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Abordado:* Ergue o rosto rachado em silêncio acusador (`idle` fumegante 6f).  
  - *Reconhecimento empático (`choice == 0`):* Abaixa o machado e dissolve-se em fumaça (`defeat` pacífico).  
  - *Ignorado:* Permanece plantado guardando a garganta da mata sob luz vermelha.  
  - *Pressionado com negação (`choice == 1` — "Você não existe!"):* Avança em corrida pesada (`run` 8f) e desfere golpes largos de brasa (`attack` 6f + `vfx`).
- **Frases-exemplo:**  
  1. *"As chamas daqui são todas suas, Huwag."*  
  2. *"Vai passar por cima de nós outra vez pra fingir que salvou o lago?"*  
  3. *(Narração ao aceitar)* *"A silhueta se desfez entre as árvores como fumaça fria."*
- **Mudança de atitude ao longo da fase:**  
  Invisível em Dose Normal e ausente no Ato 3 real; surge apenas na Dose Maior e reage diretamente à escolha do jogador entre **aceitação** (dissipação) ou **negação** (combate de alto risco).

---

### Ficha 14 — Criaturas da Mata e Lagoa *(14A Santelmos e 14B Guardiã da Lagoa)*

#### 14A — Santelmos *(`SantelmoEnemy`)*
- **Papel e Classificação:** 13 focos ígneos ao longo de `forest_trail` nos Atos 1 e 2 (desaparecem no Ato 3). **Combate Puro** (`idle`, `walk`, `run`, `attack` + `vfx` ígneo separado, `hurt`, `defeat`).
- **Aparência (`96×96`):** Chama espiritual filipina estilizada em formas orgânicas ondulantes (sem bloqueio quadrado), núcleo branco-dourado envolto por línguas de fogo laranja-carmesim e olhos estreitos incandescentes, inclinando-se na direção exata de movimento/bote em todas as 8 direções.
- **Comportamento & Fraqueza:** Sem fala; patrulham clareiras, investem com `attack` de labareda (impacto marcado em `f2`), recuam em flash azul diante da **Magia de Água** (dano dobrado) e apagam-se em fumaça (`defeat` 6f) na mesma escala até sumir do chão.

#### 14B — Guardiã da Lagoa *(`AquaticCreature`)*
- **Nome, idade, ocupação e papel na história:**  
  **Guardiã da Lagoa**, guardiã mítica dos três ovos azuis na Clareira (`forest_clearing`). Conduz o **dilema ético do Ato 1** (*Conversar / Observar / Atacar / Afastar-se* -> `003` / `004`) e concede a Magia de Água (`016`); na **Dose Maior** do Ato 2 expõe a metáfora dos três ovos que mascaravam três capacetes vazios; no **Ato 3**, desaparece dando lugar à água real (`025`). *(Encontro de Dilema: Interação Pacífica ou Combate.)*
- **Aparência (`96×96`):** Ser anfíbio alto e gracioso com silhueta orgânica fluida: torso delgado coberto por escamas em **4 tons turquesa e azul-profundo**, **barbatanas translúcidas compridas nos antebraços, ombros e crista dorsal** ondulando em atraso com a água, cauda submersa e olhos dourados luminosos. Golpeia/abençoa com **onda de água em camada `vfx/` separada**.
- **Personalidade, Jeito de Falar, Objetivo e Medo:**  
  Solene, serena, protetora e observadora (*defeito:* indiferente ao medo humano quando alguém se aproxima armado). Fala em cadência cerimonial sobre água que preserva a vida contra o fogo destrutivo; na Dose Maior torna-se reflexo sombrio de culpa.
- **Reações de interação (ligadas às poses do sprite):**  
  - *Conversar / Observar:* Ondula com barbatanas abertas abençoando o bombeiro (`interact_talk` / `bless`).  
  - *Receber Magia de Água:* Absorve o fluxo azul sem sofrer dano, iluminando as escamas.  
  - *Atacar / Forçar os ovos (`004`):* Recua em dor (`hurt` 4f), libera onda de defesa (`attack` 6f + `vfx` aquático) e submerge (`defeat` 6f).
- **Frases-exemplo:**  
  1. *"Aquele que apaga o fogo destrutivo compreende o valor da água que preserva a vida. Leve a bênção da lagoa, jovem bombeiro."*  
  2. *"Os ovos nunca foram mágicos, Huwag. Você os contou porque não suportava contar capacetes vazios."*

---

## 4. Fluxo de Aprovação e Pastas Planejadas

Seguindo exatamente a ordem combinada:
1. **Passo 1 (este documento):** Lista completa + classificação de combate/interação + fichas detalhadas — aguardando sua validação.
2. **Passo 2 (próxima entrega após seu OK):** Geração **APENAS do protagonista (`Huwag`)** em `assets/characters/huwag/` nas variantes **Casual Dia**, **Casual Dark**, **BFP Dia** e **BFP Dark** (`96×96` transparente, 8 direções, machado fixo apenas no ataque, `vfx/` separado, `_atlas.json` e **GIFs animados de andar, ataque e morte** nas direções principais para você aprovar antes do resto do elenco).
3. **Passo 3:** Aplicação do mesmo padrão aos demais 13 personagens/entidades + retratos Light Novel em nanquim (`6+` expressões por personagem importante).
4. **Passo 4:** Remontagem completa da Fase 3 no Godot (`NpcEntity`, `PlayerController`, mapas, colisões, eventos, gatilhos, switches e guia detalhado de importação/SpriteFrames).

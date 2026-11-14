# Recursos, dependências e licenças — Huwag (Godot 4)

Este projeto segue rigorosamente as diretrizes de integridade, documentação de dependências e proveniência de assets estipuladas em `AGENTS.md`.

- **Engine:** Godot 4.7 nativo cobrindo movimentação (`CharacterBody2D`), câmera (`Camera2D`), colisões, interação (`Area2D`), interface (`Control`/`Container`), animações procedurais (`Tween`), síntese sonora PCM (`AudioStreamWAV`) e shaders de percepção (`perception_filter.gdshader`).
- **Invariante:** Não utilizar ou distribuir assets RTP proprietários do RPG Maker MZ.

---

## 1. Inventário de pacotes externos

Pacotes em uso permanecem em `res://assets/third_party/`. Pacotes arquivados anteriormente, duplicatas e gerações brutas de prototipagem pré-redesign foram removidos na higienização do repositório para evitar redistribuição indevida de material de terceiros e excesso de peso binário no Git.

### 1.1 Em uso em runtime

| Pacote | Autor / Origem | Licença / Termos | Uso no projeto |
| :--- | :--- | :--- | :--- |
| **`Modern_Interiors_Free_v2.2`** | **LimeZu** (https://limezu.itch.io) | Gratuito para projetos não-comerciais. Edição de sprites permitida. | Mobiliário contemporâneo, personagens e adereços do quartel e interiores. |
| **`Pixel Art Top Down - Basic v1.2.3`** | **Cainos** | Uso livre em projetos de jogos. | Grama, plantas, pedras e adereços de exterior. |
| **`Pixel Crawler - Free Pack (Exterior 0.1)`** | **Pixel Crawler / variados** | Uso livre com termos específicos. | Pedras (`ForestRock.tscn`) e props da floresta. |
| **`Serene_Village_revamped_v1.9`** | **LimeZu** | Não-comercial livre. | Telhados, pontes e elementos de vilarejo na rua e clareira. |
| **`Top-Down_Retro_Interior`** | **Pack comunitário** | Uso livre. | Pisos, paredes e móveis dos tilesets retrô. |

> **Fonte da verdade:** todo novo pacote externo colocado em `assets/third_party/` deve ter licença verificada e registrada nesta tabela antes de ser referenciado em cenas ou scripts.

### 1.2 Arquivados removidos na higienização pré-GitHub

Pacotes anteriormente mantidos em `_archive/` que nunca entraram no runtime após o redesign em tilesets 16×16 (`male_hero_free` [usado apenas como referência anatômica anterior], `opp-assets`, `Sprout Lands`, `Village Props v2.3.2`, `Tiny Swords`, `Mini Dungeon`, `PostApocalypse_AssetPack_v1.1.2`, `stringstar fields`, duplicata de `Modern_Interiors_Free_v2.2`, `Verdant 00`, `Admurin's Freebies`, `Pixel Horror Starter Pack` e gerações brutas pré-redesign) foram excluídos do projeto.

### 1.3 Fonte tipográfica

| Recurso | Origem | Termos | Uso |
| :--- | :--- | :--- | :--- |
| **`undertale-deltarune-extended-fixed.otf`** | Fonte pixelada estendida (Undertale / Deltarune Extended), em `res://assets/fonts/` | Uso em projeto de jogo; importada sem antialiasing (`hinting=0`, `subpixel_positioning=0`). | Fonte padrão global (`gui/theme/custom_font`) da caixa de diálogo, HUD, prompts e notificações. |

### 1.4 Addons de editor (`res://addons/`)

Em conformidade com `AGENTS.md` (*"Prefira a menor solução completa e recursos nativos do Godot antes de adicionar plugins"*), foi feita auditoria minuciosa nos 11 addons presentes no workspace (`111,56 MB`). Nove foram removidos (`ziva_agent` [proprietário/proibido redistribuir, 49–57 MB], `fennara` [ferramenta externa de captura IA, 29,3 MB], `rmsmartshape` [17,7 MB, incompatível com pixel-art 16×16], `godot_ai` [2,15 MB], `sprite_staticbody_builder` [1,94 MB], `godot_mcp_toolkit` [1,86 MB], `dialogue_manager` [0,69 MB, substituído por `DialogueBox` nativo], `antigravity_bridge` [0,02 MB, ponte pré-redesign dependente de `PIL`] e `Color grading` [0,02 MB, `CompositorEffect` incompatível com `gl_compatibility` e sem licença]).

Permanecem apenas **2 addons opcionais leves (0,52 MB ao todo)**, ambos **desativados por padrão** em `project.godot` e utilizáveis no editor caso necessário em expansões futuras:

| Addon | Versão | Licença / Termos | Justificativa de permanência |
| :--- | :--- | :--- | :--- |
| **`AsepriteWizard`** | 9.8.0 | MIT | Importador opcional de arquivos `.ase` / `.aseprite` caso novos personagens ou inimigos sejam desenhados no Aseprite. |
| **`better-terrain`** | — | *Unlicense* (domínio público) | Sistema opcional de *autotiling* para `TileMapLayer`/`TileSet` caso futuros mapas sejam pintados manualmente no editor. |

---

## 2. Proveniência dos Assets Autorais do Projeto (`res://assets/`)

### 2.1 Retratos de Diálogo em Estilo Anime (`res://assets/characters/portraits/`)
Ilustrações autorais em alta resolução (`512 × 512` px, RGBA com transparência 100%) derivadas da **Imagem 3 Canônica** aprovada pelo usuário:
- **Conjunto Casual (`res://assets/characters/portraits/huwag_casual_*.png`):**
  - `neutral`, `worried`, `tired`, `surprised`, `angry`, `determined`, `scared`, `uneasy_smile` (o sorriso tenso característico da Imagem 3) e `unfiltered` (Ato 3 dessaturado).
- **Conjunto Bombeiro BFP (`res://assets/characters/portraits/huwag_bfp_*.png` e aliases):**
  - As mesmas 9 expressões com o casaco pesado de bombeiro da BFP, gola alta e faixas refletivas.
- **Placeholders Identificados (`res://assets/characters/portraits/placeholder_*.png`):**
  - `placeholder_cap_reyes.png`, `placeholder_station_staff.png`, `placeholder_npc_barangay.png`, `placeholder_creature.png`.

### 2.2 Spritesheets Top-Down (`res://assets/characters/sprites/`)
- `huwag_casual_sheet.png` e `huwag_bfp_sheet.png` (`480 × 192` px, 10 colunas × 4 linhas de `48 × 48` px):
  - Criados com base no modelo anatômico de `male_hero_free` adaptado para 4 direções top-down (`S, W, E, N`), preservando o machado de bombeiro, alcance de 44 px e colisão nos pés.

### 2.3 Áudio Procedural de Combate (`res://scripts/audio/combat_sfx.gd`)
- Sintetizador nativo GDScript (`CombatSfx`) em memória (PCM 16-bit WAV, `22050 Hz`): `swing_miss`, `melee_hit`, `water_cast`, `player_hurt`. Zero dependências externas.

### 2.4 Cenário e Adereços Remodelados do Quarto de Huwag (`res://assets/environments/room_huwag/`)
Assets autorais gerados e corrigidos para o Quarto de Huwag na resolução nativa `640 × 360` px com amostragem Nearest Neighbor (`texture_filter = 1`), baseados na referência visual canônica filipina (Bahay Kubo) aprovada pelo usuário:
- **`room_huwag_bg.png` (`640 × 360` px) e `room_huwag_1080p.png` (`1920 × 1080` px, PNG 24-bit sem compressão destrutiva):** Fundo unificado e limpo com paredes de trança de bambu (*sawali/amakan*), piso contínuo de tábuas de madeira maciça, cama tradicional de bambu com dossel e mosquiteiro (*kulambo*), esteira trançada (*banig*) 100% íntegra (com remoção do defeito de junção/suporte fantasma no assoalho), janela aberta com vista para coqueiros e céu tropical de Agdangan, cabideiro de parede com trajes típicos pendurados (sem retículo/mira sobreposto), altar de canto com imagem sacra e velas acesas, mesa de refeição com lamparina a querosene (*tinghoy*) e canecas, gatinho dormindo (*Pusa*) e chinelos de palha (*tsinelas*). O fundo foi completamente higienizado, eliminando instâncias fantasmas de personagens, barras de HUD no topo e artefatos de fatiamento. A versão Full HD 1080p é rigorosamente ampliada via amostragem de clusters inteiros (*Nearest Neighbor* 3×), assegurando fidelidade absoluta de pixel art sem qualquer desfoque ou filtragem artificial.
- **Colisões e Interações Físicas:** Definidas na cena `scenes/levels/room_huwag.gd`. Paredes/batentes (norte, sul, leste e oeste) formam a barreira contínua contra o vazio, a cama de bambu possui volume sólido e o gato uma colisão circular no tapete; o gatilho de saída `Porta_Saida` fica isolado estritamente na soleira leste. As colisões do aparador de remédios e da mesa de refeição foram **removidas a pedido** por estarem desalinhadas com a arte de fundo (geravam paredes invisíveis no assoalho e deixavam os móveis atravessáveis); a área desses dois móveis agora é livre para caminhar.
- **Licença / Proveniência:** Elementos autorais do projeto `HuwagGodot`, sem dependência de assets proprietários de terceiros.

### 2.5 Ferramentas de Automação e Ponte com Antigravity (`addons/antigravity_bridge/`)
Plugin nativo em GDScript e Python para o editor Godot 4.7 (`Antigravity Art Studio`):
- **Painel no Editor (`addons/antigravity_bridge/ui/antigravity_dock.gd`):** Interface de geração e normalização integrada ao painel lateral do Godot com presets para cenários filipinos (Bahay Kubo, Quartel BFP, Rua de Agdangan, Ato 3).
- **Processador e Normalizador (`addons/antigravity_bridge/tools/asset_processor.py`):** Converte qualquer imagem ou conceito gerado diretamente para as especificações técnicas exatas do jogo (`640 × 360` px com amostragem *Nearest Neighbor*), impedindo distorção de aspecto ou desfoque de pixels.
- **Gerador de Cenas .tscn:** Constrói automaticamente o esqueleto de cenas com `Sprite2D` de fundo, `YSortEntities`, instância do `Player` e colisões sólidas de perímetro.
- **Licença / Proveniência:** Ferramenta autoral interna do projeto sob licença MIT.

### 2.6 Entidades de Folclore Filipino e Reformulação da Floresta / Clareira
- **Santelmo (`res://scenes/enemies/santelmo.tscn` / `res://scripts/enemies/santelmo.gd`):** Fagulha viva e espírito de fogo incandescente (*Apoy sa Ilang*) oriundo da mitologia tradicional filipina (*Mitolohiyang Pilipino* - Domínio Público). Substitui os goblins genéricos e dialoga tematicamente com a ocupação de bombeiro da BFP do protagonista Huwag, possuindo fraqueza elementar à magia de água (+100% dano crítico) e vulnerabilidade a golpes de machado.
- **Texturas de Alta Resolução Pixel-Art:**
  - `res://assets/enemies/santelmo.png`: Chama viva estilizada de 32×32 px com núcleo incandescente e partículas de fagulha.
  - `res://assets/environments/pond_organic.png`: Lagoa natural em curva orgânica (256×200 px) com margem de seixos/lama e profundidade translúcida em tons de turquesa e anil.
  - `res://assets/props/blue_egg_nest.png`: Ninho de galhos e musgo com 3 ovos azuis brilhantes na margem.
  - `res://assets/characters/aquatic_creature.png`: Guardiã aquática da lagoa (*Sirena / Kataw* do folclore filipino).
  - `res://assets/tilesets/forest_natural_tileset.tres`: Tileset nativo Godot 4 gerado via `scripts/utils/forest_procedural_assets.gd`.
- **Cenários Sinuosos com Y-Sort:** `res://scenes/levels/forest_trail.tscn` (trilha em S com largura mínima de 96px e clusters de árvores volumosas) e `res://scenes/levels/forest_clearing.tscn` (clareira circular com lagoa suave e ninho de ovos). Versões originais preservadas como backup em `forest_trail_legacy.tscn` e `forest_clearing_legacy.tscn`.
- **Licença / Proveniência:** Código e lógica desenvolvidos internamente sob licença MIT; folclore tradicional em domínio público; texturas geradas sob medida para o projeto Huwag.

### 2.7 Apresentação Nativa em 1920×1080 e Acesso à Guardiã da Lagoa
- **Apresentação em 1080p com Integer Scaling:**
  - Configuração em `project.godot`: `viewport_width = 640`, `viewport_height = 360`, `window_width_override = 1920`, `window_height_override = 1080`, `stretch/mode = "canvas_items"`, `stretch/aspect = "keep"`, `default_texture_filter = 0` (Nearest Neighbor).
  - Escala inteira 3× para preenchimento de telas Full HD sem bordas pretas laterais e sem mixels ou desfoque bilinear. A interface (`Control`, `CanvasLayer`, fontes de 8-9pt e barras de vigor) é redimensionada proporcionalmente, garantindo legibilidade imediata em 1080p.
- **Acessibilidade e Interação da Guardiã da Lagoa (`scenes/levels/forest_clearing.tscn`):**
  - Ajuste de colisão de água profunda (`PondWaterBody`) para raio 48.0 px centrado em `(495, 240)`, permitindo que Huwag caminhe naturalmente pela margem arenosa e água rasa entre `x = 420` e `x = 445`.
  - Inclusão do nó `CreatureInteractable` com raio 65.0 px (`Interactable`), emitindo prompt contextual `[E] Observar / Conversar: Guardiã da Lagoa` e diálogo narrativo com a criatura aquática.
  - Inclusão de `NestInteractable` no `EggNest` em `(610, 240)` para exame dos ovos azuis (`[E] Examinar / Coletar: Ninho com Ovos Azuis`).
- **Validação Automatizada:**
  - Suíte de quarto: `tests/test_full_room_suite.gd` (8/8 testes aprovados).
  - Suíte de clareira e quarto: `tests/test_clearing_interaction_and_room.gd` (100% aprovada).
  - Suíte de floresta e Santelmo: `tests/test_forest_santelmo.gd` (100% aprovada).
  - Capturas visuais em GPU física registradas em `docs/screenshots/quarto_huwag_1080p.png`, `docs/screenshots/rua_agdangan_1080p.png`, `docs/screenshots/trilha_floresta_1080p.png` e `docs/screenshots/clareira_boss_agua_1080p.png`.

### 2.8 Integração Autoral da Rua de Agdangan (Dia e Noite) e Fluxo Casa <-> Rua
- **Arquivos-Fonte de Alta Resolução (`res://assets/`):**
  - `rua dia.jpg` e `rua noite.jpg` (`7808 × 2176` px): Ilustrações canônicas da cidade costeira de Agdangan (Quezon, Filipinas) cobrindo praia, pórtico de entrada ("Welcome to Agdangan"), quadra de basquete do barangay, casa de Huwag, Sari-Sari Store, posto comunitário com mural, Quartel dos Bombeiros (BFP Agdangan Fire Station) com caminhão na garagem, karinderya com mesas externas e triciclos azuis, bairro residencial murado, igreja colonial de pedra e estrada para a floresta.
  - `quarto huwag.jpg` (`5504 × 3072` px): Cenário interior autêntico em estilo *Bahay Kubo*.
- **Estrutura em Godot 4.7 (`scenes/levels/StreetPreview.tscn` / `street_preview.gd`):**
  - Resolução no espaço de jogo: `1952 × 544` px (escala inteira 0.25× mantendo nitidez e clusters de pixel art).
  - Camadas separadas: `BackgroundDay`, `BackgroundNight` (com crossfade/alternância diurna e noturna conforme o ciclo de tempo e switches de Ato), `CityCollisions` (`StaticBody2D` com corpos físicos precisos para paredes, cercas, postes, veículos e fundações) e `YSortEntities` (`PlayerController` de Huwag).
- **Fluxo Jogável Bidirecional:**
  - Huwag começa dentro de sua casa, caminha até a porta leste e sai diretamente para a calçada diante de sua residência (`Vector2(569, 395)`, virado para baixo).
  - Pressionando `[E]` na porta da casa (`Casa de Huwag`), retorna ao interior do quarto diante da saída (`Vector2(540, 220)`, virado para a esquerda).
- **10 Interações Exclusivas com Elementos Visíveis:**
  - `Casa_Huwag` (Porta da casa), `Quadra_Basquete` (Tabela/quadra), `Sari_Sari` (Mercearia local), `Mural_Barangay` (Informativos), `Caminhao_Bombeiros` (Viatura BFP na garagem), `Entrada_Quartel` (Porta do quartel), `Karinderya_Triciclo` (Triciclo azul), `Igreja_Agdangan` (Igreja colonial no alto), `Cais_Praia` (Píer sobre o mar) e `Estrada_Floresta` (Saída a leste para a trilha).
- **Validação Automatizada:** `tests/test_new_street_flow.gd` (9/9 testes aprovados) e `tests/test_full_room_suite.gd` (8/8 testes aprovados).
- **Capturas Registradas:** `docs/screenshots/shot1_quarto_porta.png`, `docs/screenshots/shot2_rua_saida_casa.png`, `docs/screenshots/shot3_rua_dia_sari_sari.png`, `docs/screenshots/shot4_rua_dia_quartel_bfp.png`, `docs/screenshots/shot5_rua_dia_triciclo_karinderya.png` e `docs/screenshots/shot6_rua_noite_agdangan.png`.

### 2.9 Nova Direção Visual, Menu Inicial, Áudio e Conclusão dos Atos 1–3
- **Organização e Arquivamento Reversível:**
  - Pacotes externos avulsos (`Verdant 00`, `Admurin's Freebies`, etc.) movidos com preservação integral de termos para `res://assets/_archive/loose_external_packs/`, mantido **fora do Git** para não redistribuir material de terceiros.
  - Arquivos brutos gerados por IA (`quarto huwag.jpg`, `rua dia.jpg`, `rua noite.jpg`) arquivados em `res://assets/_archive/raw_ai_generations/`, também fora do Git.
  - Textos de licença desses pacotes preservados em [`third_party_licenses/`](third_party_licenses/).
  - Cenas e scripts legados movidos para `res://scenes/levels/_archive/`. A integridade do pipeline do Godot é garantida pelos arquivos `.gdignore`.
- **Capa e Menu Inicial Autoral:**
  - `res://assets/ui/title_cover.png`: Ilustração autoral em pixel art `640 × 360` px representando a noite sobre Agdangan, o resplendor avermelhado do horizonte, silhueta de Huwag Matitiis em farda BFP com faixas refletivas brilhantes, partículas incandescentes de fuligem e silhuetas fantasmagóricas de memórias na fumaça.
  - `res://scenes/menu/TitleScreen.tscn` / `scenes/menu/title_screen.gd`: Menu funcional navegável por teclado, mouse e controle. Opções: *Novo Jogo* (reinicia e abre Ato 1), *Continuar* (detecta e resume o save real com resumo de Ato e local), *Opções & Som* (sliders de volume Master/Música/SFX e alternância de redução de flashes e efeitos VHS) e *Sair do Jogo* (fecha a aplicação com fade-out suave).
  - **Estética de fita VHS do Menu Inicial (à la FNAF VHS):** OSD de videocassete (`REC` com ponto piscante, `► PLAY`, timecode `HH:MM:SS` em contagem e etiqueta `SP · TAPE 01`), banda de rastreamento rolando, ruído de comutação de cabeça na base da tela, cursor `►` piscante nos botões (sem a caixa de foco padrão do tema) e eventos ocasionais de *glitch* (rasgo horizontal, aberração cromática e estática) com o efeito sonoro `vhs_glitch`, respeitando as opções de acessibilidade (redução de flashes e desligamento dos efeitos VHS). A capa e a tipografia `HUWAG` passam pelo filtro `perception_filter` (com tremida analógica sutil), enquanto menu, OSD e modal permanecem nítidos por serem desenhados acima da camada de filtro.
- **Sistema de Áudio Procedural Autoral (`scripts/autoload/audio_manager.gd`):**
  - Gerador nativo em GDScript via PCM 16-bit WAV (22.050 Hz) com zero dependências externas ou restrições de licença.
  - Trilhas em loop: `title_theme` (drone analógico e ressonância), `morning_ambience` (brisa tropical matinal e gorjeios sutis), `afternoon_ambience` (calor opressivo e cigarras), `night_ambience` (grilos e tensão noturna), `act3_ambience` (zumbido elétrico de 60Hz e silêncio desolador), `vhs_memory_bgm` (arpejo lo-fi com efeito de wow & flutter de fita) e `fire_hazard` (rugido de labaredas e crepitação).
  - Efeitos sonoros (SFX): `ui_hover`, `ui_select`, `ui_back`, `ui_dialogue`, `save_chime`, `step`, `extinguish`, `santelmo_cry` e `vhs_glitch`.
- **Shader de Percepção e Estética VHS Controlada (`shaders/perception_filter.gdshader`):**
  - Uniformes em tempo real: `afternoon_mix`, `night_mix`, `unfiltered_mix`, `vhs_scanline_alpha`, `vhs_noise_intensity`, `vhs_chromatic_aberration`, `vhs_tracking_jitter`, `vhs_tracking_band`, `vhs_head_switch`, `vhs_dropout` e `vhs_tear`.
  - Preserva nitidez absoluta de pixel art via `filter_nearest` com integer scaling em 1920×1080.
  - `shaders/vhs_glitch_tear.gdshader`: efeito de glitch de tela cheia (rasgo de blocos + estática) disponível para uso futuro em cenas que não usem outra passagem de `hint_screen_texture`; a tela inicial atual usa o rasgo embutido em `perception_filter` (`vhs_tear`) para evitar duas leituras de tela no mesmo frame.
- **Minigame de Memória / Trauma do Ato 3 (`scenes/levels/vhs_memory_minigame.tscn`):**
  - Sequência retro em estética VHS contextualizando o incêndio da fábrica de 2025 que originou o trauma de Huwag. Desvio de fagulhas com telegrafia justa e coleta de 4 fragmentos de memória que desvendam a verdade sobre os comprimidos.
- **Sequência Final e Créditos do Ato 3 (`scenes/menu/EndingCredits.tscn`):**
  - Conclusão da jornada em que Huwag visita a clareira no Ato 3, contempla as águas reais da lagoa, deposita sua insígnia em memória dos companheiros caídos e aceita que sobreviver é uma oportunidade de continuar protegendo Agdangan.
- **Validação Automatizada Integral:**
  - Suíte completa: `tests/test_full_acts_flow.gd` (100% de aprovação em todos os 6 blocos de teste).
  - Capturas reais em GPU gravadas em `docs/screenshots/menu_inicial_capa.png`, `docs/screenshots/ato1_quarto_huwag.png`, `docs/screenshots/ato1_quartel_bfp.png`, `docs/screenshots/ato1_clareira_boss.png`, `docs/screenshots/ato3_minigame_vhs_trauma.png`, `docs/screenshots/ato3_rua_sem_filtro.png` e `docs/screenshots/final_creditos_ato3.png`.

### 2.10 Reestruturação Visual e Narrativa — Identidade FNAF Minigames / Yume Nikki

Reconstrução estética, narrativa e estrutural dos 4 cenários principais seguindo a hierarquia artística **1. FNAF Minigames (identidade visual retrô principal) -> 2. Yume Nikki (surrealismo, vazio e estranheza) -> 3. Chrono Trigger (composição top-down) -> 4. Pokémon Game Boy (leitura espacial e escala)**:

- **Tilesets Retrô Dual-Perception (`assets/tilesets/retro/`):**
  - Gerados proceduralmente de forma autoral pelo script `scripts/tools/build_retro_tilesets.gd` (licença MIT / autoral do projeto) em grade `16×16` px com variantes `normal` e `distorted` (`TileMapLayer` dual por cena):
    - `interior_fnaf_normal.png` / `interior_fnaf_normal_tileset.tres` e `interior_fnaf_distorted.png` / `interior_fnaf_distorted_tileset.tres`
    - `town_fnaf_normal.png` / `town_fnaf_normal_tileset.tres` e `town_fnaf_distorted.png` / `town_fnaf_distorted_tileset.tres`
    - `forest_fnaf_normal.png` / `forest_fnaf_normal_tileset.tres` e `forest_fnaf_distorted.png` / `forest_fnaf_distorted_tileset.tres`
- **Spritesheets dos Bombeiros BFP e Versões Distorcidas (`assets/characters/sprites/`):**
  - Todos padronizados em grades `128×128` (`4×4` quadros de `32×32`, direções Abaixo / Esquerda / Direita / Acima) mantendo a escala de `huwag_bfp_sheet.png`:
  - **Gerados com ferramenta de geração de imagens (`image-generator`) e normalizados em script autoral:**
    - `npc_cap_reyes_bfp_sheet.png`, `npc_bombeiro_ato_sheet.png`, `npc_bombeiro_santos_sheet.png`, `npc_enfermeira_maria_sheet.png` (equipe BFP em uniforme de bombeiro/socorrista).
    - `distorted_aling_nena_sheet.png`, `distorted_bombeiro_sheet.png`, `distorted_kuya_ben_sheet.png` (versões surreais / carbonizadas do Ato 2 em dose alta).
  - **Síntese pixel art autoral com paleta retrô (fallback de cota da ferramenta de imagem preservando dimensões e proporções de referência):**
    - `distorted_luningning_sheet.png` (espectro da criança com rosto branco estático e olhos vazios inspirado em FNAF Minigames).
  - **Derivados dos pacotes de referência LimeZu já licenciados no projeto (ver Seção 1):**
    - `npc_aling_nena_sheet.png`, `npc_kuya_ben_sheet.png`, `npc_toby_sheet.png`, `npc_feirante_sheet.png`.
- **Retratos CRT Retrô FNAF (`assets/characters/portraits/`):**
  - 12 bustos `96×96` px autorais (com scanlines CRT sutis para exibição na `DialogueBox`), sem dependências de terceiros: `fnaf_aling_nena.png`, `fnaf_bombeiro_ato.png`, `fnaf_bombeiro_santos.png`, `fnaf_cap_reyes.png`, `fnaf_enfermeira_maria.png`, `fnaf_feirante.png`, `fnaf_kuya_ben.png`, `fnaf_toby.png`, `fnaf_distorted_aling_nena.png`, `fnaf_distorted_bombeiro.png`, `fnaf_distorted_kuya_ben.png`, `fnaf_distorted_luningning.png`.
- **Arquitetura de Cenários Reconstruídos e Sistemas de Ato 2:**
  - `scripts/levels/retro_level_helpers.gd`: construtor compartilhado de piso/paredes duplos (`TileMapLayer`), objetos FNAF/Yume Nikki e iluminação pontual retrô.
  - Backups integrais das versões anteriores preservados em `scenes/levels/_archive/pre_redesign_backup/` (ignorados por `.gdignore`).
  - `RoomHuwag.tscn` (`scenes/levels/room_huwag.gd`), `FireStation.tscn` (`scenes/levels/fire_station.gd` — multi-ala com Recepção, Despacho/Rádio, Galpão de Viaturas, Enfermaria e Escritório do Cap. Reyes), `StreetPreview.tscn` (`scenes/levels/street_preview.gd` — avenida estendida `2880×560` conectando moradores, barracas de mercado e quartel ao Ato 3), `forest_trail.tscn` (`scripts/levels/forest_trail.gd` / wrapper `ForestCorridor.tscn` — labirinto estendido `2560×768` com bifurcações Norte/Sul, riacho com pontes de tronco, bacia silenciosa, poço seco, 13 `SantelmoEnemy` com dificuldade crescente até `140` HP sem alterar o sistema de combate, e espectro `NPC_Vulto_Bosque`) e `forest_clearing.tscn` (`scripts/levels/forest_clearing.gd` / wrapper `ForestClearing.tscn` — santuário `960×576` com lagoa, guardiã, resgate do gato e espelho do Ato 3).
  - `scripts/characters/npc_entity.gd` + `scripts/autoload/game_state.gd` + `scenes/ui/dialogue_box.gd` + `scenes/main/main.gd`: suporte à escolha de dose no Ato 2 (`is_higher_dose()` / `higher_dose_changed` persistido em `save_game()`/`load_game()`), troca dinâmica de spritesheet/luzes/diálogos entre estado normal e distorcido, e escolhas erradas de diálogo (`conflict_choices`) que convertem o NPC em inimigo hostil (`turn_hostile()`) combatível em cena.
  - **Validação integral adicionada em `tests/test_redesign_comprehensive.gd`** executando junto às demais suítes em `Godot.exe --headless`.

### 2.11 Higienização, Separação `scenes/` × `scripts/` e Preparação para GitHub
- Remoção dos diretórios `_archive/` (`assets/_archive/` e `scenes/levels/_archive/`), fundos/retratos duplicados e obsoletos pré-redesign (`assets/environments/`, duplicatas `huwag_*.png` sem prefixo de traje, `placeholder_cap_reyes.png`, `placeholder_station_staff.png`) e testes/capturas antigas incompatíveis com a arquitetura atual.
- Padronização dos scripts `.gd` em `scripts/<domínio>/` (movendo os scripts remanescentes de `scenes/` para `scripts/main/`, `scripts/menu/`, `scripts/ui/`, `scripts/characters/`, `scripts/components/` e `scripts/levels/`), preservando todas as cenas `.tscn` e aliases de compatibilidade em `scenes/`.
- Remoção do caminho absoluto local em `scripts/tools/build_retro_tilesets.gd` (substituído por `res://docs/logs/retro_tilesets_preview.png`).
- Regeneração das capturas de tela em `docs/screenshots/` refletindo fielmente o visual atual FNAF Minigames / Yume Nikki.





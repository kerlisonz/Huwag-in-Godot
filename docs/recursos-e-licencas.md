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
| **`Modern_Interiors_Free_v2.2`** | **LimeZu** (https://limezu.itch.io) | Gratuito para projetos não-comerciais. Edição de sprites permitida. | Mobiliário contemporâneo, paredes (`Room_Builder_free_16x16`), eletrônicos, balcões BFP e adereços em `interiors_v2`. |
| **`Pixel Art Top Down - Basic v1.2.3`** | **Cainos** | Uso livre em projetos de jogos. | Grama, plantas, pedras e adereços de exterior. |
| **`Pixel Crawler - Free Pack (Exterior 0.1)`** | **Pixel Crawler / variados** | Uso livre com termos específicos. | Pedras (`ForestRock.tscn`) e props da floresta. |
| **`Serene_Village_revamped_v1.9`** | **LimeZu** | Não-comercial livre. | Grama, areia, píer, cercas, floreiras, falésias e árvores costeiras em `agdangan_town_v2` e clareira retrô. |
| **`Top-Down_Retro_Interior`** | **Pack comunitário** | Uso livre. | Pisos, paredes e móveis dos tilesets retrô. |
| **`town_rpg_pack`** | **Luis Zuno (`@ansimuz`)** (`ansimuz.com`) | **CC0** (`http://creativecommons.org/publicdomain/zero/1.0/`, `license.txt`). | Pinheiro fino (`1×6`), cachoeira animada e detalhes rurais em `forest_v2` e `agdangan_town_v2`. |
| **`lpc-tileset-16x16`** | **adrix89** (`tiled-terrains`), **buch** (`orthographic-outdoor-tiles` CC0 / `outdoor-tiles-again` CC-BY 3.0), **Lanea Zimmerman (Sharm)**, **Tuomo Untinen**, **George_** e contribuidores LPC (`attribution.txt` / `LPC_Terrain_Attribution.txt`) | **CC-BY-SA 3.0** / **GNU GPL 3.0** (subcomponentes em CC-BY 3.0 / CC0). | Bordas de lama/penhasco, água animada (3 quadros), grama alta, pinheiros e arbustos em `forest_v2` e mar animado em `agdangan_town_v2`. |
| **`tileset_16x16_interior`** | **Bonsaiheldin** (`http://bonsaiheld.org`) | **CC-BY-SA 3.0** (`http://creativecommons.org/licenses/by-sa/3.0/`, `Credits.txt`). | Camas, mesas, portas, janelas, tapetes, cadeiras, cozinha, cortinas e castiçal em `interiors_v2`. |
| **`oga_16x16_jrpg_forest`** (`dark_forest.png`) | **`bart`** (OpenGameArt: `https://opengameart.org/content/oga-16x16-jrpg-sprites-tiles` / `16x16-jrpg-tilesets-enlarged-2x`) | **CC-BY 3.0** (`ATTRIBUTION.txt`). | Platô de penhascos e gruta, árvore retorcida, Árvore Ancestral `14×18`, pontes e cercas de madeira em `forest_v2`. |

> **Fonte da verdade e triagem `16×16`:** todo novo pacote externo colocado em `assets/third_party/` deve ter licença verificada e registrada nesta tabela antes de ser referenciado em cenas ou scripts. Pacotes em escala `32×32`/`64×64`, mistos (`oga_lpc_mixed_32x32`) ou avulsos não utilizados (`oga_16x16_jrpg_unselected`) foram segregados em `res://assets/_archive/` com `.gdignore` (pastas `__MACOSX` e metadados `._*` removidos) para garantir grid estrito de `16×16` pixels sem mixels.

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

### 2.12 Revitalização Urbana, Shader de Vento e Ambientação Dinâmica (Fase 2)
- **Shader Autoral de Vento (`res://shaders/wind_sway.gdshader`):**
  - Shader `canvas_item` autoral compatível com `gl_compatibility` e amostragem `filter_nearest` (ancoragem na base via `vertical_anchor`, deslocamento pixel-sharp via `round()` e tremor adicional por `distortion_jitter` em Dose Maior), aplicado via `RetroLevelHelpers.apply_wind_sway(...)`. Licença / Proveniência: Autoral do projeto (MIT), zero dependências externas.
- **Novos Adereços Procedurais de Desordem Urbana e Vegetação (`res://scripts/levels/retro_level_helpers.gd`):**
  - Geradores pixel-art em tempo de execução (variantes normal e distorcida sem assets externos): `trash_pile` (`28×20`), `market_crates` (`36×24`), `abandoned_tricycle` (`44×28`), `abandoned_car_wreck` (`76×36`), `utility_box` (`20×32`), `overgrown_weeds` (`32×20`), `corner_shrub` (`28×28`) e `clothesline_post` (`48×36`).
- **Camadas Ambientais e Iluminação 2D (`street_preview.gd`, `forest_trail.gd`, `forest_clearing.gd`):**
  - `StreetPreview`: enriquecimento dos `TileMapLayer`s urbanos (vielas de terra, desgaste de meio-fio, poças e manchas), camada procedural `OverheadWiresDrawer` (`OverheadWiresLayer`) com fiação elétrica emaranhada, derivações para telhados e fios rompidos oscilando ao vento, 5 `PointLight2D` de postes com reator piscante e faíscas (`CPUParticles2D`), 7 `PointLight2D` de janelas/fachadas e sistemas `CPUParticles2D` de poeira e fumaça urbana sincronizados com Ato e Dose.
  - `ForestTrail` e `ForestClearing`: aplicação de `wind_sway.gdshader` em árvores, arbustos (`corner_shrub`) e mato invasivo (`overgrown_weeds`), além de sistemas `CPUParticles2D` de poeira/esporos e névoa da lagoa sincronizados com o ciclo dos Atos 1–3.

### 2.13 Sistema de NPCs Personalizados, Shader de Distorção do Ato 2 e Correção de Combate (Fase 3)
- **Spritesheets 16-bit Personalizados (`scripts/tools/build_custom_npc_sheets.gd` -> `assets/characters/sprites/`):**
  - Gerados proceduralmente de forma autoral (licença MIT / projeto) em grade `480×192` (`10×4` células de `48×48` px, 4 direções com ciclos Idle, Caminhada e Ação/Golpe nas colunas `6..9`, proporções coesas com `huwag_bfp_sheet.png`), substituindo os sheets genéricos LimeZu e placeholders:
    - `npc_aling_nena_sheet.png` (Aling Nena — avental da sari-sari e golpe/varredura com vassoura)
    - `npc_kuya_ben_sheet.png` (Kuya Ben — boné de mecânico, toalha no ombro e golpe com chave inglesa)
    - `npc_toby_sheet.png` e `distorted_toby_sheet.png` (Toby normal e distorcido em silhueta infantil com bote sombrio)
    - `npc_feirante_sheet.png` e `distorted_feirante_sheet.png` (Feirante com chapéu tradicional *salakot*, avental de feira e faca nas variantes normal/distorcida)
    - `npc_luningning_sheet.png` (Senhora Luningning — variante normal de vigília com xale escuro e lanterna)
- **Retrato CRT da Senhora Luningning (`assets/characters/portraits/fnaf_luningning.png`):**
  - Busto autoral `96×96` px com scanlines CRT e borda `#C77DFF`, vinculado em `scripts/dialogue/character_profiles.gd` (`is_placeholder = false`).
- **Shader de Distorção do Ato 2 (`res://shaders/npc_distortion.gdshader`):**
  - Shader `canvas_item` autoral compatível com `gl_compatibility` e sheets `10×4`, aplicando esticamento vertical por vértice, espasmos horizontais, fatiamento glitch contido na célula ativa, aberração cromática e descoloração carmesim-escura modulada por `distortion_intensity` e `hostile_boost`. Licença: Autoral do projeto (MIT).
- **Sistema de Intoxicação e Combate Seguro (`game_state.gd`, `npc_entity.gd`, `player.gd`):**
  - Variável `Intoxicacao` em `GameState` sincronizada com Dose Normal (`1`), Dose Maior (`2`), Overdose (`3`) e transição de Atos (`0` no Ato 1/3).
  - Correção do crash em combate no Ato 2: `NpcEntity.query_melee_hit` passou a aceitar `hit_ids: Variant` (`Dictionary` ou `Array`) e retornar `Array[Dictionary]` (junto com `query_water_hit`), `set_deferred` aplicado nas alterações de `InteractArea` e `CollisionShape2D`, guarda contra referências nulas/fora da árvore em `_process_hostile`, suporte completo a `apply_hit` / `take_damage` / `receive_damage` no `PlayerController` e logs `[NpcEntity]` / `[PlayerController]` no debugger.
  - Validação completa adicionada em `tests/test_phase3_npc_distortion_combat.gd`.

### 2.14 Refatoração da Fase 3 — Elenco 8 Direções (`672×384`) e Fichas Narrativas (Etapas 1–2)
- **Documentação de Elenco e Fichas (`docs/fichas-de-personagens.md`):**
  - Especificação autoral (MIT / projeto) das 14 fichas de personagens/entidades no estilo *Light Novel / Visual Novel*, padrão de pastas por personagem e grade `14×8` (`672×384` px, células `48×48` px) para 8 direções (`down`, `left`, `right`, `up`, `down_left`, `down_right`, `up_left`, `up_right`) e animação por papel (combate vs. interação/corrida).
- **Gerador Procedural 8-Dir e Retratos CRT (`scripts/tools/build_phase3_8dir_sheets.gd`):**
  - Script autoral em GDScript (licença MIT / zero dependências externas) que gera spritesheets `672×384` (`14×8`), cópias de transição `480×192` (`10×4`) em `assets/characters/sprites/` e retratos CRT `96×96` em `assets/characters/portraits/` e nas pastas individuais, respeitando o traço de contorno escuro `#0E0D12` e proporções `~30 px` de referência de `npc_enfermeira_maria_sheet.png` (com `npc_enfermeira_maria_sheet.png`, `npc_bombeiro_santos_sheet.png`, `fnaf_enfermeira_maria.png` e `fnaf_cap_reyes.png` preservados como referências):
    - Pastas com variantes pacífica + distorcida (`normal_sheet.png`, `distorted_sheet.png`, `portrait.png`, `distorted_portrait.png`): `cap_reyes/`, `enfermeira_maria/`, `bombeiro_ato/`, `bombeiro_santos/`, `aling_nena/`, `kuya_ben/`, `mang_tomas/`, `mang_carding/` (novo pescador do píer), `toby/`, `senhora_luningning/` (forma distorcida própria e gatinho na coluna 13) e `lola_rosa/` (nova anciã erborista reintroduzida).
    - Pastas de ameaças/entidades: `vulto_bosque/` (`hostile_sheet.png`, `portrait.png`), `santelmo/` (`combat_sheet.png`) e `aquatic_creature/` (`guardian_sheet.png`, `portrait.png`).

### 2.15 Reconstrução 96×96 do Protagonista Huwag — Passo 2 de 4
- **Gerador Pixel Rig e Encoder Nativo (`scripts/tools/pixel_rig/pixel_art_canvas.gd`, `scripts/tools/pixel_rig/gif89a_encoder.gd`, `scripts/tools/build_huwag_96_assets.gd`):**
  - Pipeline 100% autoral em GDScript 4 (licença MIT, zero dependências externas/Python/ImageMagick), renderizando células `96×96` px em pixel art nítida sem antialiasing, com âncora fixa no chão `(48, 84)`, sombreamento discreto em 4 tons, exportador GIF89a LZW transparente nativo e metadados JSON (`huwag_atlas.json`).
  - **Ativos gerados em `res://assets/characters/huwag/`** nas 4 variantes (`casual_day/`, `casual_dark/`, `bfp_day/`, `bfp_dark/`): 192 tiras RGBA horizontais em 8 direções (`idle` 6f, `walk` 8f, `run` 8f, `attack` 6f, `hurt` 4f, `defeat` 6f), 32 tiras separadas de rastro do machado em `vfx/` (`impact_frame = 2` e dissipação no frame `3`), 192 pré-visualizações `.gif` transparentes (`scale = 2`, `192×192` px) em `gifs/` e 4 arquivos `huwag_atlas.json`. Licença / Proveniência: Autoral do projeto (MIT).

### 2.16 Substituição 96×96 do Protagonista Huwag (`huwag_v2`) — Trajes Bombeiro & Casual
- **Ativos e Pipelines (`res://assets/sprites/huwag_v2/` + `scripts/tools/process_huwag_v2_sheets.{py,gd}`):**
  - Folhas brutas geradas por IA para o projeto (`raw/huwag_bombeiro_raw_v5.jpg`, `raw/huwag_casual_raw_v1.jpg`, fundo chromakey `#00FF00`, sem texto e sem itens/extintor nas mãos), processadas de modo idêntico pelo script Python+Pillow e pelo executor nativo GDScript 4 (`Gif89aEncoder`). Licença / Proveniência: Autoral / ativos exclusivos do projeto Huwag, zero dependências externas.
  - Backups preservados dos sheets anteriores `48×48` em `assets/sprites/huwag_v2/backup/` (`huwag_bfp_sheet.png.bak`, `huwag_casual_sheet.png.bak`).
  - Saídas normalizadas em `bombeiro/` e `casual/`: células `96×96` (`height=80 px`, `foot_anchor=(48, 90)`), `huwag_{bombeiro,casual}_sheet_96x96.png` (`384×384`), tiras `huwag_idle_{down,up,left,right}.png` (`96×96`) e `huwag_walk_{down,up,left,right}.png` (`384×96`), `huwag_atlas.json`, recursos nativos `huwag_{bombeiro,casual}_spriteframes.tres` (`8` animações, sem `action_*`) e `8` previews GIF animados (`192×192`, `8 FPS`) em `gifs/`.
  - Integração no `Player` (`scenes/characters/Player.tscn`, `scripts/characters/player.gd`), normalização de trajes em `GameState` (`casual` / `bfp` / `bombeiro`), calibração de câmera (`zoom=1.18`), colisão (`16×12`) e seletor no Armário (`RoomHuwag`) e Menu (`Main.tscn` `OutfitButton`).

### 2.17 Reformulação Pixel Art 16-bit do Protagonista (`huwag_v3`), Spritesheets por Finalidade e Sistema de Combate/Combo/Esquiva
- **Gerador e Reconstrutor Pixel Art (`scripts/tools/build_huwag_rebuilt_sprites.gd` -> `res://assets/sprites/huwag_v3/{casual,bombeiro}/`):**
  - Reconstrução autoral em pixel art 16-bit (`18×28` px lógicos dentro de célula `48×48` px, renderizada em escala inteira `1:1` `scale = Vector2(1.0, 1.0)` com `TEXTURE_FILTER_NEAREST` e pés ancorados em `y = 39`, igualando a proporção exata dos tiles `16×16` e NPCs do mundo).
  - Baseada fielmente na identidade visual da folha oficial do protagonista (Imagem 1: cabelo loiro espetado com contorno marrom-escuro quente `#462814` e brilho `#FAF0B8`, olheiras `#925E42`, jaqueta preta aberta com zíper cinza sobre camisa escura, calça verde-oliva e tênis cinza; mais variante Bombeiro BFP com faixas refletivas amarelo-ouro e laranja) e refinada segundo a qualidade de clusters e fluidez de animação da referência artística (Imagem 2). Licença / Proveniência: Autoral do projeto (MIT), zero dependências externas.
  - **8 Spritesheets separados por finalidade para cada traje (`casual/` e `bombeiro/`):**
    - `spritesheet_idle.png` (`192×192`, `4 direções × 4 frames`, respiração sutil e piscada natural, `5.0 FPS`)
    - `spritesheet_walk.png` (`288×192`, `4 direções × 6 frames`, ciclo fluido com poses de passagem e *bounce* de `1 px`, `9.5 FPS`)
    - `spritesheet_run.png` (`288×192`, `4 direções × 6 frames`, corrida com inclinação frontal, impulso ampliado e balanço do cabelo, `12.5 FPS`)
    - `spritesheet_attack.png` (`240×192`, `4 direções × 5 frames`, golpe primário com antecipação, extensão de braço/lâmina, arco de corte e recuperação, `15.0 FPS`)
    - `spritesheet_combo.png` (`384×192`, `4 direções × 8 frames`: `combo2_*` corte reverso cruzado `4f` + `combo3_*` finalizador pesado dourado `4f`, `16.0 FPS`)
    - `spritesheet_dodge.png` (`192×192`, `4 direções × 4 frames`, esquiva ágil com linhas de velocidade, `14.0 FPS`)
    - `spritesheet_hurt.png` (`144×192`, `4 direções × 3 frames`, recuo e expressão de impacto, `10.0 FPS`)
    - `spritesheet_death.png` (`288×192`, `4 direções × 6 frames`, cambaleio, queda de joelhos e colapso horizontal no chão, `8.0 FPS`)
  - **Recursos `SpriteFrames` e Pré-visualizações:** `huwag_casual_spriteframes.tres`, `huwag_bombeiro_spriteframes.tres` e GIFs animados em `res://assets/sprites/huwag_v3/{casual,bombeiro}/gifs/`.
- **Sistema de Animações e Combate Integrado (`scripts/characters/player.gd`, `scenes/characters/Player.tscn`):**
  - Máquina de estados de animação com transições suaves (`death` -> `hurt` -> `dodge` -> `attack`/`combo2`/`combo3` -> `jump` -> `run`/`walk` -> `idle`) e parâmetros `@export` configuráveis no Inspetor.
  - Sistema de **Combo encadeado de 3 estágios** (`perform_melee_attack()`): Estágio 1 (`attack_*`, `25` dmg, raio `44 px`, arco `120°`) -> Estágio 2 (`combo2_*`, `32` dmg, raio `48.4 px`, arco `138°`, varredura reversa) -> Estágio 3 (`combo3_*`, `45` dmg, raio `53.7 px`, arco `160°`, impacto dourado).
  - Mecânica de **Esquiva (`perform_dodge()`, teclas `[Z]` / `[L]`)**: impulso rápido na direção ativa com animação `dodge_*`, rastro fantasma e janela de invulnerabilidade (*i-frames*) com feedback `"ESQUIVA!"`.
  - Reações de **Dano (`hurt_*`)** e **Morte (`death_*`)** integradas a `apply_hit()`, `take_damage()`, `receive_damage()` e `revive()`.
  - Validação automatizada e capturas reais em jogo registradas via `tests/test_protagonist_combat_and_animations.gd` e `tests/test_huwag_v2_integration.gd`.

### 2.18 Reformulação Orgânica 16-bit de NPCs — Lote 1: Núcleo BFP (`res://assets/sprites/npcs/`)
- **Pipeline Pixel-Art Modular Orgânico (`scripts/tools/npc_pixel_rig/npc_humanoid_templates.gd`, `scripts/tools/npc_pixel_rig/npc_sprite_builder.gd`, `scripts/tools/build_npc_lote1_bfp.gd`):**
  - Pipeline 100% autoral em GDScript 4 (licença MIT, zero dependências externas) construído diretamente sobre a matriz anatômica `32×32` orgânica e paleta restrita 16-bit de `huwag_v3` (`Canvas48`, células `48×48` px, pés ancorados em `y = 39`, `offset = Vector2(0, -7)`, escala `1:1` Nearest Neighbor).
  - Gera recursos `SpriteFrames` modulares (`idle`, `walk`, `talk`, `attack`, `hurt`, `death` em 4 direções `down`, `up`, `left`, `right`) para variantes **normal** e **distorted** (incluindo postura sutilmente torta de `1 px` e olhos/expressões perturbadas):
    - **`cap_reyes/`** (`Capitão Reyes` — quepe oficial BFP com viseira cinza, bigode grisalho/farto, traje de comando azul-marinho e golpe de varredura com lanterna/bastão âmbar)
    - **`bombeiro_ato/`** (`Bombeiro Ato` — capacete amarelo de visor escuro, jaqueta BFP de golas erguidas e golpe vertical com croque/machado deslocado à frente/mão dominante)
    - **`bombeiro_santos/`** (`Bombeiro Santos` e `NPC_Bombeiro_Ronda` em `StreetPreview` — cabelo cacheado escuro com *rim light* frio de 1 px para recorte, uniforme técnico escuro com faixas refletivas e arco diagonal com mangote/bocal)
    - **`enfermeira_maria/`** (`Enfermeira Maria` — cabelo castanho repartido com coque baixo e elástico vermelho, avental/jaleco clínico branco-azulado com bolso e estocada rápida com tesoura médica/seringa)
- **Integração em Runtime (`scenes/characters/NpcEntity.tscn`, `scripts/characters/npc_entity.gd`, `scripts/levels/fire_station.gd`, `scripts/levels/street_preview.gd`):**
  - Suporte nativo em `NpcEntity` a `AnimatedSprite2D` com `SpriteFrames` (`normal_frames_path` / `distorted_frames_path`) preservando compatibilidade com sheets legados (`10×4`) durante a transição dos Lotes 2–3, com seleção de estados `idle`, `walk`, `talk`, `attack`, `hurt` e `death` persistente no chão ao derrotar o NPC.

### 2.19 Reformulação Orgânica 16-bit de NPCs — Lote 2: Civis, Toby e Vulto (`res://assets/sprites/npcs/`)
- **Módulos Complementares Lote 2 (`scripts/tools/npc_pixel_rig/npc_lote2_templates.gd`, `scripts/tools/npc_pixel_rig/npc_lote2_ext.gd`, `scripts/tools/build_npc_lote2_civis.gd`):**
  - Extensão 100% autoral do pipeline `huwag_v3` `48×48` (`Canvas48`, pés em `y = 39`, `offset = Vector2(0, -7)`, escala `1:1` Nearest Neighbor) preservando silhueta orgânica para todo o elenco civil adulto (pacote completo 24 animações: `idle`, `walk`, `talk`, `attack`, `hurt`, `death` em 4 direções), variante infantil proporcionada para Toby (`idle`, `walk`, `talk`, `hurt`, sem ataque/morte) e forma espectral calcinada para o Vulto do Bosque:
    - **`aling_nena/`** (`Aling Nena` — blusa/avental marrom-roxo de quitanda, lenço/tiara de cozinha e golpe amplo com cabo/cerdas de vassoura `*tambo*`)
    - **`kuya_ben/`** (`Kuya Ben` — boné aba curva virado/reto de motorista de jeepney, jaqueta jeans azul-índigo aberta e golpe pesado com chave inglesa metálica)
    - **`mang_tomas/`** (`Mang Tomas` / `NPC_Feirante` — avental branco de feira com manchas sutis, boné escuro e cutelo de açougue/feira projetado à frente do corpo)
    - **`mang_carding/`** (`Mang Carding` — bandana turquesa com pontas traseiras, rede diagonal e lamparina na interação; remo longo de madeira em punho no ataque e na queda)
    - **`toby/`** (`Toby` — grade infantil reduzida ancorada em `y = 39`, boné laranja esportivo, camiseta verde com mochila 2×2; apenas `idle`, `walk`, `talk` e `hurt`)
    - **`senhora_luningning/`** (`Senhora Luningning` — coque prateado alto, xale roxo-vinho drapeado em V nas costas e ataque espectral de lamparina dupla)
    - **`lola_rosa/`** (`Lola Rosa` — lenço floral branco com trança grisalha, blusa creme *baro*, cesta de ervas *lagundi* e rajada giratória de folhas verdes / cinzas em brasa)
    - **`vulto_bosque/`** (`Vulto Calcinado do Bosque` / `NPC_Vulto_Bosque` — silhueta BFP carbonizada com capacete rachado em brasa, olhos incandescentes, corte largo de cinzas/brasas e desintegração em monte de cinzas com capacete partido no chão)
- **Integração em Runtime (`scripts/levels/fire_station.gd`, `scripts/levels/street_preview.gd`, `scripts/levels/forest_trail.gd`):**
  - `Velhinha_Espera` (`FireStation`) migrada para `senhora_luningning_{normal,distorted}_spriteframes.tres`.
  - `StreetPreview` migrado integralmente para Lote 2 `.tres` (`NPC_Aling_Nena`, `NPC_Kuya_Ben`, `NPC_Toby`, `NPC_Feirante`, `NPC_Vigilia_Leste`) com adição em cena de `NPC_Mang_Carding` no píer oeste (`Cais_Praia`) e `NPC_Lola_Rosa` na calçada oeste ao lado da Casa de Huwag.
  - `NPC_Vulto_Bosque` (`forest_trail.gd`) migrado para `vulto_bosque_{normal,distorted}_spriteframes.tres`.

### 2.20 Etapa 1 (Portraits Anime Pixel Art 96×96), Reformulação da UI/HUD e Staging da Etapa 2 (Sprites Corrompidos Grotescos)
- **Autoria & Licença:** Produção original autoral integrada ao projeto `Huwag-in-Godot` (uso exclusivo no jogo, sem reutilização de assets ou RTP do RPG Maker MZ), gerada proceduralmente em GDScript nativo no Godot 4 (`Nearest Neighbor`, sem dependências ou plugins externos).
- **Etapa 1 — Portraits `96×96` Integrados (`scripts/tools/deploy_etapa1_portraits.gd`, `scripts/dialogue/character_profiles.gd`):**
  - Implantação dos retratos aprovados `96×96` em `assets/characters/portraits/` e `assets/sprites/portraits/` (incluindo novas variantes `huwag_casual_distorted.png`, `huwag_bfp_distorted.png`, `Santelmo` e `Rádio BFP / Fita VHS`).
  - Atualização de `CharacterProfiles` e das falas em `room_huwag.gd`, `street_preview.gd`, `forest_trail.gd` e `forest_clearing.gd` para usar exclusivamente os retratos aprovados (`is_placeholder = false`, sem overlays rígidos antigos).
- **Reformulação Visual da UI/HUD & Sistema de Estamina (`scripts/ui/huwag_ui_theme.gd`, `scripts/ui/dialogue_box.gd`, `scenes/ui/DialogueBox.tscn`, `scenes/main/Main.tscn`, `scripts/main/main.gd`, `scenes/menu/TitleScreen.tscn`, `scripts/menu/title_screen.gd`, `scripts/autoload/game_state.gd`, `scripts/characters/player.gd`):**
  - `DialogueBox` redesenhada em retângulo horizontal inferior (`448×88`), borda crisp `1px`, cantos retos `0px`, friso superior VHS sutil, moldura quadrada de retrato `72×72` com `TEXTURE_FILTER_NEAREST`, indicador animado em pixel art `9×6`, painel de escolhas alinhado acima da caixa e tema automático carmesim escuro para falas/estado `distorted` (e cinza clínico no Ato III).
  - `Main` HUD superior esquerda substituída por **3 Corações em pixel art (`13×12` — cheio, meio, vazio)** com pulso em vida crítica (`<= 1` coração) + **mini barra de estamina** compacta ligada a correr (`Shift`), esquivar (`Z/L`) e atacar (`J/Espaço`) com regeneração em repouso/caminhada.
  - `HudTopRight`, notificações toast (`StatusLabel`), modal `[F1]` (`ControlsModal`) e modal de opções da tela inicial (`OptionsModal`) unificados no mesmo padrão minimalista `1px` / `0px`.
- **Etapa 2 (Staging — Aguardando Aprovação Visual):**
  - Scripts `scripts/tools/corrupted_v4/corrupted_v4_builder.gd`, `corrupted_v4_designs.gd` e `build_corrupted_v4_preview.gd` geram todas as 12 entidades corrompidas reconstruídas (silhuetas anatômicas grotescas em `48×48`, âncora `y = 39`, contorno `1px`, `toby` restrito a 16 animações sem `attack`/`death`) isoladas em `assets/sprites/corrupted_v4_preview/` para aprovação antes de substituir `assets/sprites/npcs/*/distorted/`.

### 2.21 Spritesheets VFX 16-bit (`patch-gg/pixelfx` v0.3.1)
- **Origem & Licença:** Efeitos pré-renderizados offline via `patch-gg/pixelfx` v`0.3.1` (`https://github.com/patch-gg/pixelfx`), licenciado sob **MIT License** (permite uso comercial, modificação e redistribuição sem restrição de copyleft). Repositório Node.js gerador mantido externamente em `scratch/pixelfx` (nenhum código JavaScript ou plugin terceiro adicionado em `addons/`, respeitando a diretriz de solução nativa Godot 4 em `AGENTS.md`).
- **Assets Gerados & Adaptados em `res://assets/vfx/`:**
  - `axe_slash_amber.png` + `axe_slash_amber_spriteframes.tres` (`melee/sword-slash`, `radius: 26`, paleta âmbar/aço BFP, 13f @ 24fps).
  - `axe_slash_crimson.png` + `axe_slash_crimson_spriteframes.tres` (`melee/sword-slash`, `radius: 28`, paleta carmesim/distorção, 13f @ 24fps).
  - `claw_swipe_horror.png` + `claw_swipe_horror_spriteframes.tres` (`melee/claw-swipe`, paleta horror carmesim, 15f @ 20fps).
  - `hit_spark.png` + `hit_spark_spriteframes.tres` (`impacts/hit-spark`, `height: 10`, faísca direcional de combate, 11f @ 24fps).
  - `blunt_hit.png` + `blunt_hit_spriteframes.tres` (`impacts/blunt-hit`, `height: 8`, impacto pesado com poeira escura, 18f @ 20fps).
  - `impact_dust.png` + `impact_dust_spriteframes.tres` (`impacts/heavy-landing`, nuvem de poeira/cinzas de esquiva/queda, 27f @ 18fps).
  - `water_jet.png` + `water_jet_spriteframes.tres` (`water/water-jet`, `length: 56`, jato da habilidade de água, 18f @ 18fps loop).
  - `water_splash.png` + `water_splash_spriteframes.tres` (`water/splash`, `stone: false`, respingo/extinção por água, 40f @ 18fps).
  - `water_ripples.png` + `water_ripples_spriteframes.tres` (`water/ripples`, anéis na água top-down 3/4, 24f @ 12fps loop).
  - `santelmo_flame.png` + `santelmo_flame_spriteframes.tres` (`fire/spirit-flame`, chamas espectrais laranja-âmbar do Santelmo, 36f @ 12fps loop).
  - `shadow_flames.png` + `shadow_flames_spriteframes.tres` (`shadow/shadow-flames`, chamas sombrias carmesim de núcleo preto para distorção/Ato II, 29f @ 12fps loop).
  - `grasping_hands.png` + `grasping_hands_spriteframes.tres` (`shadow/grasping-hands`, erupção de mãos sombrias em poça carmesim, 39f @ 14fps).
  - `campfire_ember.png` + `campfire_ember_spriteframes.tres` (`fire/campfire`, `height: 16`, fogueira/brasas com fumaça e faíscas, 36f @ 12fps loop).
  - `candle_flicker.png` + `candle_flicker_spriteframes.tres` (`fire/candle`, vela tremulante com halo quente para interiores/vigília, 40f @ 10fps loop).
  - `vfx_manifest.json` (metadados de grid, FPS, pivô e offset centralizado), `scripts/tools/build_pixelfx_spriteframes.gd` (conversor nativo para `SpriteFrames`/`AtlasTexture`) e `scripts/vfx/vfx_library.gd` (`VfxLibrary` com reprodução via `AnimatedSprite2D` + `TEXTURE_FILTER_NEAREST`).
- **Integração Atual:** Integrado ao combate do protagonista (`scripts/characters/player.gd` — corte de machado normal/combo/Ato III dessaturado, faísca de acerto, jato e respingo de água, poeira de esquiva) e ao `Santelmo` (`scripts/enemies/santelmo.gd` — chama animada acoplada + respingo/dispersão ao morrer). Efeitos ambientais/horror adicionais (`water_ripples`, `shadow_flames`, `grasping_hands`, `claw_swipe_horror`, `campfire_ember`, `candle_flicker`) estão prontos para a reconstrução dos mapas e novos inimigos.

### 2.22 Pipeline de Atlases 16×16 v2 e Iluminação Atmosférica (Fase 1)
- **Origem & Licença:** Assets originais/sintetizados em pixel art `16×16` + composições derivadas dos pacotes `third_party/` documentados na Seção 1.1 (preservando `CC0`, `CC-BY 3.0`, `CC-BY-SA 3.0 / GPL 3.0` e termos não-comerciais de LimeZu).
- **Geradores e Catálogo Nativo (Godot 4.7 GDScript):**
  - `scripts/tools/v2_tilesets/atlas_painter.gd` (`V2AtlasPainter`): Blit `16×16`, color-keying branco para folhas sem canal alfa (`dark_forest.png`), gradação cromática por Ato (`normal`, `distorted`, `act3`), faixas de sombra projetada (`add_shadow_strips`), animação de água (3 quadros) e configuração de `TileSet` (`PhysicsLayer 0`, `CustomData` `surface_type`/`is_water`/`blocks_light`, `texture_origin` e `y_sort_origin` calibrados).
  - `scripts/tools/v2_tilesets/agdangan_pixel_props.gd` (`AgdanganPixelProps`): Síntese pixel art 16-bit de identidade costeira filipina adaptada ao tom sombrio de Huwag: asfalto rachado com poças/meio-fio/praça, reboco e madeira *kahoy*, janelas *capiz/jalousie*, telhados *yero* cinza e enferrujado, paredes/garagem BFP, coqueiros inclinados `3×6`, bananeira `2×3`, postes de luz `1×5`, fachada *Sari-Sari Store* `5×4`, casas provinciais `6×5`, viatura BFP `5×3`, triciclo filipino `3×2`, barco *banca/katig* `4×2`, paredes *sawali* e esteira *banig*.
  - `scripts/tools/build_v2_world_tilesets.gd` e `scripts/levels/v2_tile_catalog.gd` (`V2TileCatalog`): Emitem e catalogam 9 folhas/recursos em `res://assets/tilesets/v2/` — `forest_v2_{normal,distorted,act3}`, `agdangan_town_v2_{normal,distorted,act3}` e `interiors_v2_{normal,distorted,act3}` (`.png` + `*_tileset.tres` com `[ext_resource]`).
- **Shaders e Rig Atmosférico 2D:**
  - `shaders/fog_drift.gdshader`: Névoa pixelada quantizada compatível com `gl_compatibility` e filtro `Nearest`, com mistura para névoa rubra no modo distorcido (`distortion_mix`).
  - `shaders/canopy_proximity.gdshader`: Balanço sutil pixel-snapped para copas e atenuação suave (`proximity_fade_enabled`) ao passar atrás da vegetação (`player_world_pos`).
  - `scripts/levels/atmosphere_rig.gd` (`AtmosphereRig`): Presets de `CanvasModulate`, `PointLight2D` com `SHADOW_FILTER_NONE`, `LightOccluder2D` e `attach_lit_vfx()` (integrado ao `VfxLibrary`, preservando supressão automática de fogs/chamas sobrenaturais no Ato III via `is_act3`).





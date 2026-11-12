# Recursos, dependências e licenças — Huwag (Godot 4)

Este projeto segue rigorosamente as diretrizes de integridade, documentação de dependências e proveniência de assets estipuladas em `AGENTS.md`.

- **Engine:** Godot 4.7 nativo cobrindo movimentação (`CharacterBody2D`), câmera (`Camera2D`), colisões, interação (`Area2D`), interface (`Control`/`Container`), animações procedurais (`Tween`), síntese sonora PCM (`AudioStreamWAV`) e shaders de percepção (`perception_filter.gdshader`).
- **Invariante:** Não utilizar ou distribuir assets RTP proprietários do RPG Maker MZ.

---

## 1. Inventário de pacotes externos

Pacotes em uso ficam em `res://assets/third_party/`. Pacotes não usados, incompatíveis ou duplicados ficam em `res://assets/_archive/`, que é ignorado pelo Godot via `.gdignore`.

Para não redistribuir material de terceiros nem inflar o repositório, as pastas `assets/_archive/loose_external_packs/` e `assets/_archive/raw_ai_generations/` permanecem **apenas localmente** (ignoradas pelo Git). Os textos de licença correspondentes estão em [`third_party_licenses/`](third_party_licenses/).

### 1.1 Em uso em runtime

| Pacote | Autor / Origem | Licença / Termos | Uso no projeto |
| :--- | :--- | :--- | :--- |
| **`Modern_Interiors_Free_v2.2`** | **LimeZu** (https://limezu.itch.io) | Gratuito para projetos não-comerciais. Edição de sprites permitida. | Mobiliário contemporâneo, personagens e adereços do quartel e interiores. |
| **`Pixel Art Top Down - Basic v1.2.3`** | **Cainos** | Uso livre em projetos de jogos. | Grama, plantas, pedras e adereços de exterior. |
| **`Pixel Crawler - Free Pack (Exterior 0.1)`** | **Pixel Crawler / variados** | Uso livre com termos específicos. | Floresta, props, fogueiras e criaturas. |
| **`Serene_Village_revamped_v1.9`** | **LimeZu** | Não-comercial livre. | Telhados, pontes e elementos de vilarejo na clareira. |
| **`Top-Down_Retro_Interior`** | **Pack comunitário** | Uso livre. | Pisos, paredes e móveis do quartel. |

### 1.2 Arquivados (referência, incompatíveis ou duplicata)

| Pacote | Autor / Origem | Licença / Termos | Motivo do arquivamento |
| :--- | :--- | :--- | :--- |
| **`male_hero_free`** | **Ozzbit Games** (https://ozzbit-games.itch.io) | Gratuito para uso pessoal / não-comercial. Modificações permitidas. Crédito: *"Ozzbit Games"*. | Base anatômica de referência para os spritesheets de Huwag; não usado em runtime. |
| **`opp-assets`** | **Open Pixel Project** (http://www.openpixelproject.com) | **CC0 1.0 Universal — Domínio Público**. | Não referenciado no código. |
| **`char free`, `fishing_free`, `free version`, `Interior free`, `nature free`, `town free`, `winter free`** | **Shubibubi** (Sprout Lands) | Uso livre não-comercial. Não redistribuir como asset puro. | Não referenciados no código. |
| **`Pixel Art Platformer - Village Props v2.3.2`** | **Cainos** | Uso em jogos. | Perspectiva lateral incompatível com o top-down. |
| **`Tiny Swords (Free Pack)`** | **Pixel Frog** | CC0 / Uso livre. | Perspectiva isométrica e fantasia medieval incompatíveis com Agdangan. |
| **`[FREE] Mini Dungeon Tileset`** | **Anokolisa** | Uso livre com termos específicos. | Fantasia medieval escura incompatível com o tom. |
| **`PostApocalypse_AssetPack_v1.1.2`**, **`stringstar fields`** | Variados | Verificar termos antes de usar. | Não referenciados no código. |
| **`Modern_Interiors_Free_v2.2_duplicate`** | LimeZu | Mesmos termos do pacote original. | Duplicata de `Modern_Interiors_Free_v2.2(1)`. |
| **`loose_external_packs`**, incluindo **Verdant 00** | csaf / variados | Uso comercial permitido no pacote Verdant 00, sem atribuição; ver termos locais. | Amostras externas não usadas em runtime; mantidas localmente fora do Git. |
| **`Admurin's Freebies`** | **Admurin** | Uso em projetos permitido; proibida a redistribuição isolada como pacote de assets. | Referência visual não usada em runtime; licença em [`third_party_licenses/Admurin_Freebies_LICENSE.txt`](third_party_licenses/Admurin_Freebies_LICENSE.txt). |
| **`Pixel Horror Starter Pack`** | **Morbidember** | **MIT License**. | Referência visual não usada em runtime; licença em [`third_party_licenses/Morbidember_Pixel_Horror_MIT.txt`](third_party_licenses/Morbidember_Pixel_Horror_MIT.txt). |
| **`raw_ai_generations`** | Gerações internas | Fontes brutas de IA usadas para derivar cenários autorais. | Mantidas apenas localmente para proveniência; não versionadas. |

> **Fonte da verdade:** antes de mover um pacote de `_archive/` para `third_party/`, confirme a licença no arquivo original do pacote e registre a decisão aqui.

### 1.3 Fonte tipográfica

| Recurso | Origem | Termos | Uso |
| :--- | :--- | :--- | :--- |
| **`undertale-deltarune-extended-fixed.otf`** | Fonte pixelada estendida (Undertale / Deltarune Extended), em `res://assets/fonts/` | Uso em projeto de jogo; importada sem antialiasing (`hinting=0`, `subpixel_positioning=0`). | Fonte padrão global (`gui/theme/custom_font`) da caixa de diálogo, HUD, prompts e notificações. |

### 1.4 Addons de desenvolvimento (`res://addons/`)

Ferramentas de editor usadas no desenvolvimento. Apenas `antigravity_bridge` está habilitado por padrão em `project.godot`; os demais podem ser ativados em **Projeto → Configurações do Projeto → Plugins**.

| Addon | Versão | Licença / Termos | Uso |
| :--- | :--- | :--- | :--- |
| **`antigravity_bridge`** | 1.0.0 | MIT (ferramenta autoral) | Ponte de geração e normalização de assets. |
| **`AsepriteWizard`** | 9.8.0 | MIT | Importação de arquivos Aseprite. |
| **`better-terrain`** | sem versão declarada | *Unlicense* (domínio público) | Autotile alternativo para TileMap/TileSet. |
| **`Color grading`** | 1.0 | Termos não incluídos no pacote; verificar antes de redistribuir. | Efeitos de composição e color grading. |
| **`dialogue_manager`** | 4.2.0 | MIT | Edição de diálogos. |
| **`fennara`** | sem versão declarada | MIT | Ferramentas auxiliares e captura de jogo. |
| **`godot_ai`** | 4.3.1 | MIT | Assistente de IA no editor. |
| **`godot_mcp_toolkit`** | 1.1.2 | MIT | Ponte para ferramentas MCP. |
| **`rmsmartshape`** | 3.3.2 | MIT | Editor de formas (SmartShape2D). |
| **`sprite_staticbody_builder`** | 1.0.0 | MIT | Geração de corpos estáticos a partir de sprites. |
| **`ziva_agent`** | sem versão declarada | **Proprietária (Zivash, Inc.)** — não redistribuir. | Agente integrado ao editor. |

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
- **Colisões e Interações Físicas:** Ajustadas milimetricamente na cena `scenes/levels/room_huwag.gd` com volumes sólidos para cama de bambu, armário/aparador e mesa de refeição, barreira contínua nas paredes leste e oeste contra vazamento para o vácuo, e gatilho de saída `Porta_Saida` isolado estritamente na soleira leste (impedindo ativação indevida ao redor da mesa).
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
- **Sistema de Áudio Procedural Autoral (`scripts/autoload/audio_manager.gd`):**
  - Gerador nativo em GDScript via PCM 16-bit WAV (22.050 Hz) com zero dependências externas ou restrições de licença.
  - Trilhas em loop: `title_theme` (drone analógico e ressonância), `morning_ambience` (brisa tropical matinal e gorjeios sutis), `afternoon_ambience` (calor opressivo e cigarras), `night_ambience` (grilos e tensão noturna), `act3_ambience` (zumbido elétrico de 60Hz e silêncio desolador), `vhs_memory_bgm` (arpejo lo-fi com efeito de wow & flutter de fita) e `fire_hazard` (rugido de labaredas e crepitação).
  - Efeitos sonoros (SFX): `ui_hover`, `ui_select`, `ui_back`, `ui_dialogue`, `save_chime`, `step`, `extinguish`, `santelmo_cry` e `vhs_glitch`.
- **Shader de Percepção e Estética VHS Controlada (`shaders/perception_filter.gdshader`):**
  - Uniformes em tempo real: `afternoon_mix`, `night_mix`, `unfiltered_mix`, `vhs_scanline_alpha`, `vhs_noise_intensity`, `vhs_chromatic_aberration` e `vhs_tracking_jitter`.
  - Preserva nitidez absoluta de pixel art via `filter_nearest` com integer scaling em 1920×1080.
- **Minigame de Memória / Trauma do Ato 3 (`scenes/levels/vhs_memory_minigame.tscn`):**
  - Sequência retro em estética VHS contextualizando o incêndio da fábrica de 2025 que originou o trauma de Huwag. Desvio de fagulhas com telegrafia justa e coleta de 4 fragmentos de memória que desvendam a verdade sobre os comprimidos.
- **Sequência Final e Créditos do Ato 3 (`scenes/menu/EndingCredits.tscn`):**
  - Conclusão da jornada em que Huwag visita a clareira no Ato 3, contempla as águas reais da lagoa, deposita sua insígnia em memória dos companheiros caídos e aceita que sobreviver é uma oportunidade de continuar protegendo Agdangan.
- **Validação Automatizada Integral:**
  - Suíte completa: `tests/test_full_acts_flow.gd` (100% de aprovação em todos os 6 blocos de teste).
  - Capturas reais em GPU gravadas em `docs/screenshots/menu_inicial_capa.png`, `docs/screenshots/ato1_quarto_huwag.png`, `docs/screenshots/ato1_quartel_bfp.png`, `docs/screenshots/ato1_clareira_boss.png`, `docs/screenshots/ato3_minigame_vhs_trauma.png`, `docs/screenshots/ato3_rua_sem_filtro.png` e `docs/screenshots/final_creditos_ato3.png`.




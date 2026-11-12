# Recursos, dependências e licenças — Huwag (Godot 4)

Este projeto segue rigorosamente as diretrizes de integridade, documentação de dependências e proveniência de assets estipuladas em `AGENTS.md`.

- **Engine:** Godot 4.7 nativo cobrindo movimentação (`CharacterBody2D`), câmera (`Camera2D`), colisões, interação (`Area2D`), interface (`Control`/`Container`), animações procedurais (`Tween`), síntese sonora PCM (`AudioStreamWAV`) e shaders de percepção (`perception_filter.gdshader`).
- **Invariante:** Não utilizar ou distribuir assets RTP proprietários do RPG Maker MZ.

---

## 1. Inventário de pacotes externos

Pacotes em uso ficam em `res://assets/third_party/`. Pacotes não usados, incompatíveis ou duplicados ficam em `res://assets/_archive/`, que é ignorado pelo Godot via `.gdignore`.

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

> **Fonte da verdade:** antes de mover um pacote de `_archive/` para `third_party/`, confirme a licença no arquivo original do pacote e registre a decisão aqui.

### 1.3 Fonte tipográfica

| Recurso | Origem | Termos | Uso |
| :--- | :--- | :--- | :--- |
| **`undertale-deltarune-extended-fixed.otf`** | Fonte pixelada estendida (Undertale / Deltarune Extended), em `res://assets/fonts/` | Uso em projeto de jogo; importada sem antialiasing (`hinting=0`, `subpixel_positioning=0`). | Fonte padrão global (`gui/theme/custom_font`) da caixa de diálogo, HUD, prompts e notificações. |

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
- **`room_huwag_bg.png` (`640 × 360` px, PNG 24-bit sem compressão destrutiva):** Fundo unificado e limpo com paredes de trança de bambu (*sawali/amakan*), piso contínuo de tábuas de madeira maciça, cama tradicional de bambu com dossel e mosquiteiro (*kulambo*), esteira trançada (*banig*) 100% íntegra (com remoção do defeito de junção/suporte fantasma no assoalho), janela aberta com vista para coqueiros e céu tropical de Agdangan, cabideiro de parede com trajes típicos pendurados (sem retículo/mira sobreposto), altar de canto com imagem sacra e velas acesas, mesa de refeição com lamparina a querosene (*tinghoy*) e canecas, gatinho dormindo (*Pusa*) e chinelos de palha (*tsinelas*). O fundo foi completamente higienizado, eliminando instâncias fantasmas de personagens, barras de HUD no topo e artefatos de fatiamento.
- **Colisões e Interações Físicas:** Ajustadas milimetricamente na cena `scenes/levels/room_huwag.gd` com volumes sólidos para cama de bambu, armário/aparador e mesa de refeição, barreira contínua nas paredes leste e oeste contra vazamento para o vácuo, e gatilho de saída `Porta_Saida` isolado estritamente na soleira leste (impedindo ativação indevida ao redor da mesa).
- **Licença / Proveniência:** Elementos autorais do projeto `HuwagGodot`, sem dependência de assets proprietários de terceiros.


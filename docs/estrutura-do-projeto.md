# Estrutura do projeto

Organização padronizada de pastas do `Huwag-in-Godot` separando cenas (`.tscn`), scripts (`.gd`), recursos (`assets/`), shaders, testes e documentação.

## Árvore

```text
Huwag-in-Godot/
├── addons/                       # Plugins opcionais de editor (AsepriteWizard, better-terrain)
├── assets/
│   ├── characters/
│   │   ├── portraits/            # Retratos de diálogo (Huwag Casual/BFP + bustos CRT FNAF/Distorcidos)
│   │   ├── sprites/              # Spritesheets top-down (Huwag, moradores, bombeiros e formas distorcidas)
│   │   └── aquatic_creature.png  # Guardiã da lagoa
│   ├── enemies/                  # Santelmo (santelmo.png)
│   ├── fonts/                    # Fonte pixelada global (undertale-deltarune-extended-fixed.otf)
│   ├── props/                    # Adereços da clareira (blue_egg_nest.png)
│   ├── third_party/              # Pacotes externos usados em runtime para tilesets/adereços
│   ├── tilesets/retro/           # Atlases 16×16 e TileSets .tres (normal / distorted)
│   └── ui/                       # Capa da tela inicial (title_cover.png)
├── docs/                         # Continuidade, direção de arte, licenças, estrutura
│   ├── logs/                     # Artefatos locais de execução (ignorados pelo Git)
│   └── screenshots/              # Capturas atuais usadas no README (com .gdignore)
├── scenes/                       # Apenas arquivos .tscn organizados por domínio
│   ├── characters/               # Player.tscn, huwag.tscn, NpcEntity.tscn, aquatic_creature.tscn
│   ├── components/               # RotateTowardsMouse.tscn, ForestRock.tscn
│   ├── enemies/                  # santelmo.tscn
│   ├── levels/                   # RoomHuwag, StreetPreview, FireStation, forest_trail, forest_clearing, vhs_memory_minigame
│   ├── main/                     # Main.tscn
│   ├── menu/                     # TitleScreen.tscn, EndingCredits.tscn
│   └── ui/                       # DialogueBox.tscn
├── scripts/                      # Todos os scripts .gd do projeto organizados por domínio
│   ├── audio/                    # combat_sfx.gd
│   ├── autoload/                 # audio_manager.gd, game_state.gd
│   ├── characters/               # player.gd, npc_entity.gd, aquatic_creature.gd
│   ├── components/               # interactable.gd, rotate_towards_mouse.gd
│   ├── dialogue/                 # character_profiles.gd
│   ├── enemies/                  # santelmo.gd
│   ├── levels/                   # retro_level_helpers.gd e scripts de cada nível
│   ├── main/                     # main.gd
│   ├── menu/                     # title_screen.gd, ending_credits.gd
│   ├── tools/                    # build_retro_tilesets.gd
│   └── ui/                       # dialogue_box.gd
├── shaders/                      # perception_filter.gdshader e vhs_glitch_tear.gdshader
├── tests/                        # Suítes headless (test_*.gd) e capturador GPU (capture_acts_and_menu.gd)
├── AGENTS.md
├── .gitattributes
├── .gitignore
├── project.godot
└── README.md
```

## Convenções

- **Separação estrita `scenes/` vs `scripts/`:** todas as cenas `.tscn` ficam em `scenes/<domínio>/` e todo código `.gd` vive no espelho `scripts/<domínio>/`.
- **Assets autorais** ficam fora de `third_party/` e usam `snake_case`.
- **Pacotes externos** ficam em `assets/third_party/<nome original>/` para preservar a proveniência e licenças.
- **Cenas** seguem `PascalCase.tscn` (mantendo aliases `ForestCorridor.tscn` e `ForestClearing.tscn` para compatibilidade de saves); scripts seguem `snake_case.gd`.
- **Estado narrativo** vive no autoload `GameState`, nunca na UI.
- **Comunicação entre cena e UI** acontece por sinais (`request_level_change`, `request_dialogue`, `conflict_triggered`).
- **Caminhos de recurso** usam `res://` relativos à raiz do projeto.
- **Screenshots** de documentação ficam em `docs/screenshots/` com `.gdignore` para não entrar no import do Godot.

## Fluxo de cenas

```text
TitleScreen.tscn
└── (Novo Jogo / Continuar)
    └── Main.tscn
        └── LevelContainer
            ├── RoomHuwag.tscn
            ├── StreetPreview.tscn
            ├── FireStation.tscn
            ├── vhs_memory_minigame.tscn
            ├── forest_trail.tscn     (alias de compatibilidade: ForestCorridor.tscn)
            └── forest_clearing.tscn  (alias de compatibilidade: ForestClearing.tscn)
EndingCredits.tscn
```

`scripts/main/main.gd` instancia o nível atual, conecta `request_level_change` e `request_dialogue`, e mantém o HUD e a caixa de diálogo em `CanvasLayer`. As cenas `ForestCorridor.tscn` e `ForestClearing.tscn` são invólucros finos mantidos para preservar compatibilidade com saves anteriores.

## Pipeline de percepção

`GameState.perception_mode` controla o shader `shaders/perception_filter.gdshader`:

| Modo | Uniforme | Efeito |
| :--- | :--- | :--- |
| `FILTERED_MORNING` | `afternoon_mix = 0`, `unfiltered_mix = 0` | Paleta matinal com saturação controlada. |
| `FILTERED_AFTERNOON` | `afternoon_mix = 1`, `unfiltered_mix = 0` | Banho âmbar vespertino e sombras arroxeadas. |
| `UNFILTERED_ACT3` | `afternoon_mix = 0`, `unfiltered_mix = 1` | Dessaturação, contraste árido e vinheta fria. |

Em paralelo, a escolha de dose maior no Ato 2 (`GameState.is_higher_dose()` / sinal `higher_dose_changed`) ativa realidade distorcida (tilesets e NPCs surreais, interferência VHS contínua com bursts e confrontos hostis via `conflict_choices` / `NpcEntity.turn_hostile()`).

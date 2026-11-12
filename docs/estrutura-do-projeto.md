# Estrutura do projeto

Organização de pastas do `HuwagGodot` e convenções para manter o projeto previsível.

## Árvore

```text
HuwagGodot/
├── addons/                  # Plugins de desenvolvimento (AsepriteWizard, Fennara, Godot AI, Ziva)
├── assets/
│   ├── _archive/            # Pacotes não usados/incompatíveis/duplicados (ignorado pelo Godot)
│   ├── audio/               # Reservado para SFX e música
│   ├── characters/
│   │   ├── portraits/       # Retratos de diálogo (casual e BFP)
│   │   └── sprites/         # Spritesheets 4-direcionais de Huwag
│   ├── environments/
│   │   └── room_huwag/      # Fundo e adereços do quarto
│   ├── fonts/               # Fonte pixelada da UI
│   ├── third_party/         # Pacotes externos usados em runtime
│   └── ui/                  # Reservado para ícones e elementos de interface
├── docs/                    # Continuidade, direção de arte, licenças, estrutura
│   ├── logs/                # Artefatos de execução (ignorados pelo Git)
│   └── screenshots/         # Capturas usadas na documentação
├── scenes/
│   ├── characters/          # Player e futuros NPCs
│   ├── components/          # Componentes reutilizáveis (Interactable)
│   ├── levels/              # 5 cenários jogáveis
│   │   └── _archive/        # Cenas substituídas (ignoradas pelo Godot)
│   ├── main/                # Main.tscn e orquestração de cenas
│   └── ui/                  # DialogueBox e HUD
├── scripts/
│   ├── audio/               # Síntese procedural de SFX
│   ├── autoload/            # GameState
│   └── dialogue/            # Perfis de personagem e retratos
├── shaders/                 # perception_filter.gdshader
├── tests/                   # Runners headless e capturas
├── AGENTS.md
├── project.godot
└── README.md
```

## Convenções

- **Assets autorais** ficam fora de `third_party/` e usam `snake_case`.
- **Pacotes externos** ficam em `assets/third_party/<nome original>/` para preservar a proveniência.
- **Conteúdo arquivado** fica em `assets/_archive/`, com `.gdignore` para não entrar no pipeline de importação.
- **Cenas** seguem `PascalCase.tscn`; scripts seguem `snake_case.gd`.
- **Estado narrativo** vive no autoload `GameState`, nunca na UI.
- **Comunicação entre cena e UI** acontece por sinais (`request_level_change`, `request_dialogue`).
- **Caminhos de recurso** usam `res://` e são relativos à raiz do projeto.
- **Screenshots** de documentação ficam em `docs/screenshots/` e são ignorados pelo Godot.

## Fluxo de cenas

```text
Main.tscn
└── LevelContainer
    ├── RoomHuwag.tscn
    ├── StreetPreview.tscn
    ├── FireStation.tscn
    ├── ForestCorridor.tscn
    └── ForestClearing.tscn
```

`Main.gd` instancia o nível atual, conecta `request_level_change` e `request_dialogue`, e mantém o HUD e a caixa de diálogo em `CanvasLayer`.

## Pipeline de percepção

`GameState.perception_mode` controla o shader `shaders/perception_filter.gdshader`:

| Modo | Uniforme | Efeito |
| :--- | :--- | :--- |
| `FILTERED_MORNING` | `afternoon_mix = 0`, `unfiltered_mix = 0` | Cores levemente realçadas. |
| `FILTERED_AFTERNOON` | `afternoon_mix = 1`, `unfiltered_mix = 0` | Banho âmbar e sombras arroxeadas. |
| `UNFILTERED_ACT3` | `afternoon_mix = 0`, `unfiltered_mix = 1` | Dessaturação, contraste árido e vinheta fria. |

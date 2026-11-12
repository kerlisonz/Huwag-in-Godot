# Estrutura do projeto

Organização de pastas do `HuwagGodot` e convenções para manter o projeto previsível.

## Árvore

```text
HuwagGodot/
├── addons/                  # Plugins de desenvolvimento (AsepriteWizard, better-terrain,
│                            # dialogue_manager, Fennara, Godot AI, godot_mcp_toolkit,
│                            # rmsmartshape, sprite_staticbody_builder, Ziva, antigravity_bridge)
├── assets/
│   ├── _archive/            # Pacotes não usados/incompatíveis/duplicados (ignorado pelo Godot)
│   │   ├── loose_external_packs/  # Preservação local; fora do Git por licença de terceiros
│   │   ├── raw_ai_generations/    # Fontes brutas de IA; fora do Git
│   │   └── scratch_dev/           # Pré-visualizações temporárias; fora do Git
│   ├── characters/          # Retratos, spritesheets e criatura aquática
│   ├── enemies/             # Santelmo
│   ├── environments/        # Quarto, rua, floresta e lagoa
│   ├── fonts/               # Fonte pixelada da UI
│   ├── props/               # Adereços de cena
│   ├── third_party/         # Pacotes externos usados em runtime
│   ├── tilesets/            # Tilesets nativos do Godot
│   └── ui/                  # Capa e elementos de interface
├── docs/                    # Continuidade, direção de arte, licenças, estrutura
│   ├── logs/                # Artefatos de execução (ignorados pelo Git)
│   ├── screenshots/         # Capturas usadas na documentação
│   └── third_party_licenses/ # Termos de licença de assets externos arquivados
├── scenes/
│   ├── characters/          # Player, Huwag e criatura aquática
│   ├── components/          # Interactable, árvores e pedras
│   ├── enemies/             # Santelmo
│   ├── levels/              # Cenários jogáveis
│   │   └── _archive/        # Cenas e scripts substituídos (ignorados pelo Godot)
│   ├── main/                # Main.tscn e orquestração de cenas
│   ├── menu/                # TitleScreen e EndingCredits
│   └── ui/                  # DialogueBox e HUD
├── scripts/
│   ├── audio/               # Síntese procedural de SFX
│   ├── autoload/            # GameState e AudioManager
│   ├── characters/          # Lógica de criaturas
│   ├── dialogue/            # Perfis de personagem e retratos
│   ├── enemies/             # IA do Santelmo
│   ├── levels/              # Lógica de floresta e clareira
│   └── utils/               # Geração procedural de assets
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
- **Pacotes externos arquivados e fontes brutas de IA** permanecem apenas localmente (ignorados pelo Git) para preservar proveniência sem redistribuir material de terceiros; os termos ficam em `docs/third_party_licenses/`.
- **Cenas** seguem `PascalCase.tscn`; scripts seguem `snake_case.gd`.
- **Estado narrativo** vive no autoload `GameState`, nunca na UI.
- **Comunicação entre cena e UI** acontece por sinais (`request_level_change`, `request_dialogue`).
- **Caminhos de recurso** usam `res://` e são relativos à raiz do projeto.
- **Screenshots** de documentação ficam em `docs/screenshots/` e são ignorados pelo Godot.

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

`Main.gd` instancia o nível atual, conecta `request_level_change` e `request_dialogue`, e mantém o HUD e a caixa de diálogo em `CanvasLayer`. As cenas `ForestCorridor.tscn` e `ForestClearing.tscn` são invólucros finos mantidos para que saves antigos continuem carregando; o fluxo novo usa `forest_trail.tscn` e `forest_clearing.tscn`.

## Pipeline de percepção

`GameState.perception_mode` controla o shader `shaders/perception_filter.gdshader`:

| Modo | Uniforme | Efeito |
| :--- | :--- | :--- |
| `FILTERED_MORNING` | `afternoon_mix = 0`, `unfiltered_mix = 0` | Cores levemente realçadas. |
| `FILTERED_AFTERNOON` | `afternoon_mix = 1`, `unfiltered_mix = 0` | Banho âmbar e sombras arroxeadas. |
| `UNFILTERED_ACT3` | `afternoon_mix = 0`, `unfiltered_mix = 1` | Dessaturação, contraste árido e vinheta fria. |

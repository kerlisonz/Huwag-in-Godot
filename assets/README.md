# Assets

Arte, áudio e tipografia do projeto, separados entre conteúdo autoral e pacotes externos.

## Estrutura

| Pasta | Conteúdo |
| :--- | :--- |
| `characters/` | Retratos de diálogo e spritesheets 4-direcionais de Huwag. |
| `environments/` | Cenários e adereços autorais, como o quarto de Huwag. |
| `fonts/` | Fonte pixelada usada pela UI e pelo diálogo. |
| `audio/` | Reservado para SFX e música. O combate atual sintetiza áudio em runtime. |
| `ui/` | Reservado para ícones, molduras e elementos de interface. |
| `third_party/` | Pacotes externos usados em runtime. Ver `third_party/README.md`. |
| `_archive/` | Pacotes não usados, incompatíveis ou duplicados. Ignorados pelo Godot via `.gdignore`. |

## Regras

- Todo asset novo precisa de origem e licença registradas em `docs/recursos-e-licencas.md`.
- Não reutilizar assets RTP do RPG Maker MZ.
- Preferir `Nearest` para pixel art e `Linear with Mipmaps` apenas para retratos em alta resolução.
- Nomes de arquivos em `snake_case`, sem acentos e sem espaços para assets autorais.

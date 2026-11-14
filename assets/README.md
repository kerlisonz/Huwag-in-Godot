# Assets

Arte, tipografia e pacotes visuais do projeto, separados entre conteúdo autoral e pacotes externos.

## Estrutura

| Pasta | Conteúdo |
| :--- | :--- |
| `characters/` | Retratos (`portraits/`), spritesheets 4-direcionais e distorcidos (`sprites/`) e `aquatic_creature.png`. |
| `enemies/` | Sprite pixel-art do espírito de fogo `santelmo.png`. |
| `fonts/` | Fonte pixelada usada pela UI e pelo diálogo (`undertale-deltarune-extended-fixed.otf`). |
| `props/` | Adereços de cenário (`blue_egg_nest.png`). |
| `third_party/` | Pacotes externos usados como base dos tilesets e adereços em runtime. Ver [`third_party/README.md`](third_party/README.md). |
| `tilesets/retro/` | Atlases 16×16 (`normal` e `distorted`) e recursos `.tres` de `TileSet`. |
| `ui/` | Capa e elementos visuais do menu (`title_cover.png`). |

## Regras

- Todo asset novo precisa de origem e licença registradas em [`docs/recursos-e-licencas.md`](../docs/recursos-e-licencas.md).
- Não reutilizar assets RTP do RPG Maker MZ.
- Usar amostragem `Nearest` (`default_texture_filter = 0`) para preservar pixel art nítida.
- Nomes de arquivos autorais em `snake_case`, sem acentos e sem espaços.

# Assets

Arte, tipografia e pacotes visuais do projeto, separados entre conteúdo autoral e pacotes externos.

## Estrutura

| Pasta | Conteúdo |
| :--- | :--- |
| `characters/` | Retratos (`portraits/`), spritesheets 4-direcionais e distorcidos (`sprites/`) e `aquatic_creature.png`. |
| `enemies/` | Sprite pixel-art do espírito de fogo `santelmo.png`. |
| `fonts/` | Fonte pixelada usada pela UI e pelo diálogo (`undertale-deltarune-extended-fixed.otf`). |
| `props/` | Adereços de cenário (`blue_egg_nest.png`). |
| `third_party/` | Pacotes externos `16×16` curados e usados como base dos tilesets e adereços em runtime. Ver [`third_party/README.md`](third_party/README.md). |
| `_archive/` | Pacotes em escala incompatível (`32×32`/`64×64`) ou sobras não usadas (`oga_lpc_mixed_32x32`, `oga_16x16_jrpg_unselected`), ignorados via `.gdignore`. |
| `tilesets/retro/` | Atlases 16×16 legado (`normal` e `distorted`) e recursos `.tres` de `TileSet`. |
| `tilesets/v2/` | Atlases 16×16 Fase 1 (`forest_v2`, `agdangan_town_v2`, `interiors_v2` em `normal`, `distorted` e `act3`) + `*_tileset.tres`. |
| `ui/` | Capa e elementos visuais do menu (`title_cover.png`). |
| `vfx/` | Spritesheets pixel art e `SpriteFrames` `.tres` pré-renderizados via `pixelfx` (`Nearest Neighbor`). |

## Regras

- Todo asset novo precisa de origem e licença registradas em [`docs/recursos-e-licencas.md`](../docs/recursos-e-licencas.md).
- Não reutilizar assets RTP do RPG Maker MZ.
- Usar amostragem `Nearest` (`default_texture_filter = 0`) para preservar pixel art nítida.
- Nomes de arquivos autorais em `snake_case`, sem acentos e sem espaços.

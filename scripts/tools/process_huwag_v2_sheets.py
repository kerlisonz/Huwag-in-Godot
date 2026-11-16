#!/usr/bin/env python3
"""Process raw 4x4 Huwag pixel art sheets into Godot-ready 96x96 assets.

This script performs:
1. Row/column foreground segmentation via pure #00FF00 chroma-key gutters.
2. Chroma-key background removal and 1-2 px green edge despill cleanup.
3. Side-direction normalization so Row 2 (left) and Row 3 (right) use clean
   [Idle, Step A, Idle, Step B] walk cycles facing the true direction.
4. Uniform scale + shadow-baseline foot anchoring into 96x96 frames with crisp
   outline-preserving sampling and subtle JPEG palette deduplication.
5. Export of:
   - Normalized 384x384 (4x4) transparent sheet PNG
   - Per-animation transparent PNG strips (idle_* 96x96, walk_* 384x96)
   - huwag_atlas.json metadata
   - 4-direction transparent animated walk preview GIFs

Note: If Python/Pillow is not installed locally, run the functionally matching
Godot headless executor:
  Godot.exe --headless --path <project> --script res://scripts/tools/process_huwag_v2_sheets.gd
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

from PIL import Image

CELL_SIZE = 96
TARGET_CHAR_HEIGHT = 80  # Full height including compact oval foot shadow (~75px body + ~5px shadow)
FOOT_ANCHOR_X = 48
FOOT_ANCHOR_Y = 90
WALK_FPS = 8
GIF_DELAY_MS = 125

DIRECTIONS = ("down", "up", "left", "right")

# Both huwag_bombeiro_raw_v5 and huwag_casual_raw_v1 share identical raw 4x4 layout:
#   row 0: front (down)   -> cols [0..3]
#   row 1: back  (up)     -> cols [0..3]
#   row 2: mixed side     -> col 0 = clean idle facing LEFT, col 3 = clean idle facing RIGHT
#   row 3: mixed side     -> col 0 = step B facing LEFT, col 3 = step A facing LEFT
# Side walk sequences select natively drawn LEFT frames [r2c0, r3c3, r2c0, r3c0]
# and mirror them horizontally for symmetrical RIGHT frames.
DIRECTION_MAP: Dict[str, List[Tuple[int, int, bool]]] = {
    "down": [(0, 0, False), (0, 1, False), (0, 2, False), (0, 3, False)],
    "up": [(1, 0, False), (1, 1, False), (1, 2, False), (1, 3, False)],
    "left": [(2, 0, False), (3, 3, False), (2, 0, False), (3, 0, False)],
    "right": [(2, 0, True), (3, 3, True), (2, 0, True), (3, 0, True)],
}


def is_chromakey_green(r: int, g: int, b: int) -> bool:
    """Return True if pixel belongs to #00FF00 background or strong green bleed."""
    max_rb = max(r, b)
    green_excess = g - max_rb
    if g > 110 and green_excess >= 48 and max_rb < 145:
        return True
    if g > 55 and green_excess >= 36 and r < 55 and b < 55:
        return True
    return False


def remove_chromakey_and_despill(img: Image.Image) -> Image.Image:
    """Strip #00FF00 background and suppress JPEG green halo on outline pixels."""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    src = rgba.load()

    # Pass 1: Binary chromakey removal
    alpha_mask = [[255] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, _ = src[x, y]
            if is_chromakey_green(r, g, b):
                alpha_mask[y][x] = 0
                src[x, y] = (0, 0, 0, 0)

    # Pass 2: Suppress green fringe pixels bordering transparency
    for y in range(h):
        for x in range(w):
            if alpha_mask[y][x] == 0:
                continue
            touches_bg = False
            for dy in (-2, -1, 0, 1, 2):
                ny = y + dy
                if ny < 0 or ny >= h:
                    touches_bg = True
                    break
                for dx in (-2, -1, 0, 1, 2):
                    nx = x + dx
                    if nx < 0 or nx >= w or alpha_mask[ny][nx] == 0:
                        touches_bg = True
                        break
                if touches_bg:
                    break
            if not touches_bg:
                continue

            r, g, b, _ = src[x, y]
            max_rb = max(r, b)
            if g - max_rb > 14:
                new_g = max_rb
                if max_rb < 32:
                    src[x, y] = (r, min(g, max_rb), b, 255)
                else:
                    src[x, y] = (r, new_g, b, 255)

    return rgba


def _find_contiguous_bands(counts: Sequence[int], min_pixels: int = 5, max_gap: int = 2) -> List[Tuple[int, int]]:
    """Find contiguous foreground spans along an axis projection."""
    bands: List[Tuple[int, int]] = []
    in_band = False
    start = 0
    last_fg = 0
    for idx, count in enumerate(counts):
        if count >= min_pixels:
            if not in_band:
                in_band = True
                start = idx
            last_fg = idx
        elif in_band and (idx - last_fg) > max_gap:
            bands.append((start, last_fg))
            in_band = False
    if in_band:
        bands.append((start, last_fg))
    return bands


def segment_4x4_cells(rgba: Image.Image) -> List[List[Tuple[int, int, int, int]]]:
    """Locate 4x4 cell split rectangles cleanly along pure green gutters."""
    w, h = rgba.size
    px = rgba.load()

    row_counts = [sum(1 for x in range(w) if px[x, y][3] > 0) for y in range(h)]
    col_counts = [sum(1 for y in range(h) if px[x, y][3] > 0) for x in range(w)]

    y_bands = _find_contiguous_bands(row_counts, min_pixels=8, max_gap=3)
    x_bands = _find_contiguous_bands(col_counts, min_pixels=8, max_gap=3)

    if len(y_bands) == 4:
        y_splits = [0] + [(y_bands[i][1] + y_bands[i + 1][0]) // 2 for i in range(3)] + [h]
    else:
        y_splits = [round(i * h / 4.0) for i in range(5)]

    if len(x_bands) == 4:
        x_splits = [0] + [(x_bands[i][1] + x_bands[i + 1][0]) // 2 for i in range(3)] + [w]
    else:
        x_splits = [round(i * w / 4.0) for i in range(5)]

    grid: List[List[Tuple[int, int, int, int]]] = []
    for r in range(4):
        row_rects: List[Tuple[int, int, int, int]] = []
        for c in range(4):
            row_rects.append((x_splits[c], y_splits[r], x_splits[c + 1], y_splits[r + 1]))
        grid.append(row_rects)
    return grid


def measure_foreground_metrics(cell: Image.Image) -> Dict[str, float]:
    """Measure tight bounding box and bottom shadow horizontal centroid."""
    w, h = cell.size
    px = cell.load()
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)

    if max_x < min_x:
        return {"min_x": 0, "min_y": 0, "max_x": w - 1, "max_y": h - 1, "cx": w * 0.5, "height": float(h)}

    # Anchor X on the ground shadow oval centroid so hair/limbs never drift the feet sideways.
    band_top = max(min_y, max_y - max(6, int((max_y - min_y + 1) * 0.08)))
    sum_x = 0.0
    count = 0
    for y in range(band_top, max_y + 1):
        for x in range(min_x, max_x + 1):
            if px[x, y][3] > 0:
                sum_x += x
                count += 1
    cx = (sum_x / count) + 0.5 if count > 0 else (min_x + max_x + 1) * 0.5
    return {
        "min_x": float(min_x),
        "min_y": float(min_y),
        "max_x": float(max_x),
        "max_y": float(max_y),
        "cx": cx,
        "height": float(max_y - min_y + 1),
    }


def downsample_crisp_cell(
    cell: Image.Image,
    scale: float,
    anchor_src_x: float,
    anchor_src_y: float,
) -> Image.Image:
    """Resample sprite cleanly into a 96x96 canvas with outline-preserving medoids."""
    w, h = cell.size
    src = cell.load()
    out = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    dst = out.load()

    half_footprint = max(0.75, 0.5 / scale)
    for dy in range(CELL_SIZE):
        sy_center = anchor_src_y + (dy + 0.5 - FOOT_ANCHOR_Y) / scale
        sy0 = max(0, int(math.floor(sy_center - half_footprint)))
        sy1 = min(h - 1, int(math.ceil(sy_center + half_footprint)))
        for dx in range(CELL_SIZE):
            sx_center = anchor_src_x + (dx + 0.5 - FOOT_ANCHOR_X) / scale
            sx0 = max(0, int(math.floor(sx_center - half_footprint)))
            sx1 = min(w - 1, int(math.ceil(sx_center + half_footprint)))
            if sy1 < sy0 or sx1 < sx0:
                continue

            opaque: List[Tuple[int, int, int]] = []
            darks: List[Tuple[int, int, int]] = []
            total = 0
            for sy in range(sy0, sy1 + 1):
                for sx in range(sx0, sx1 + 1):
                    total += 1
                    r, g, b, a = src[sx, sy]
                    if a >= 128:
                        opaque.append((r, g, b))
                        if max(r, g, b) <= 28:
                            darks.append((r, g, b))

            if total == 0 or (len(opaque) / total) < 0.42:
                continue

            if darks and (len(darks) / len(opaque)) >= 0.30:
                best = min(darks, key=lambda c: c[0] + c[1] + c[2])
                dst[dx, dy] = (best[0], best[1], best[2], 255)
                continue

            cx_i = min(w - 1, max(0, int(round(sx_center))))
            cy_i = min(h - 1, max(0, int(round(sy_center))))
            cr, cg, cb, ca = src[cx_i, cy_i]
            if ca >= 128 and max(cr, cg, cb) > 28:
                dst[dx, dy] = (cr, cg, cb, 255)
            else:
                non_dark = [c for c in opaque if max(c) > 28] or opaque
                # Color-medoid avoids blurring adjacent bright/dark cel shades.
                best = min(
                    non_dark,
                    key=lambda a_col: sum(
                        abs(a_col[0] - b_col[0]) + abs(a_col[1] - b_col[1]) + abs(a_col[2] - b_col[2])
                        for b_col in non_dark
                    ),
                )
                dst[dx, dy] = (best[0], best[1], best[2], 255)
    return out


def deduplicate_palette(frames: List[Image.Image], initial_l1: int = 12, target_max_colors: int = 180) -> int:
    """Snap minor JPEG shade jitter cleanly onto dominant cel palette entries."""
    freq: Dict[Tuple[int, int, int], int] = {}
    for frame in frames:
        px = frame.load()
        for y in range(frame.height):
            for x in range(frame.width):
                r, g, b, a = px[x, y]
                if a >= 128:
                    freq[(r, g, b)] = freq.get((r, g, b), 0) + 1

    palette: List[Tuple[int, int, int]] = []
    remap: Dict[Tuple[int, int, int], Tuple[int, int, int]] = {}
    for col, _count in sorted(freq.items(), key=lambda kv: kv[1], reverse=True):
        matched = None
        for pcol in palette:
            if abs(col[0] - pcol[0]) + abs(col[1] - pcol[1]) + abs(col[2] - pcol[2]) <= initial_l1:
                matched = pcol
                break
        if matched is None:
            palette.append(col)
            remap[col] = col
        else:
            remap[col] = matched

    # If slight JPEG shades still exceed GIF's 255-color limit, fold remaining rare
    # colors into their closest already-established palette entry (preserving >= 180 top shades).
    if len(palette) > target_max_colors:
        kept = palette[:target_max_colors]
        for col, mapped in list(remap.items()):
            if mapped not in kept:
                remap[col] = min(
                    kept,
                    key=lambda pcol: abs(mapped[0] - pcol[0]) + abs(mapped[1] - pcol[1]) + abs(mapped[2] - pcol[2]),
                )
        palette = kept

    for frame in frames:
        px = frame.load()
        for y in range(frame.height):
            for x in range(frame.width):
                r, g, b, a = px[x, y]
                if a >= 128:
                    nr, ng, nb = remap[(r, g, b)]
                    px[x, y] = (nr, ng, nb, 255)
                else:
                    px[x, y] = (0, 0, 0, 0)

    return len(palette)


def save_transparent_gif(frames: Sequence[Image.Image], out_path: Path, scale: int = 2) -> None:
    """Write a crisp nearest-neighbor looping transparent animated GIF preview."""
    scaled = [
        f.resize((f.width * scale, f.height * scale), Image.Resampling.NEAREST) if scale > 1 else f.copy()
        for f in frames
    ]
    pal_frames: List[Image.Image] = []
    for img in scaled:
        alpha = img.getchannel("A")
        p_img = img.convert("RGB").quantize(colors=254, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
        # Remap transparent pixels strictly to palette index 255.
        transparent_mask = Image.eval(alpha, lambda v: 255 if v < 128 else 0)
        p_img.paste(255, mask=transparent_mask)
        pal_frames.append(p_img)

    pal_frames[0].save(
        out_path,
        save_all=True,
        append_images=pal_frames[1:],
        duration=GIF_DELAY_MS,
        loop=0,
        disposal=2,
        transparency=255,
    )


def process_outfit(raw_path: Path, out_dir: Path, outfit: str, global_scale: float) -> Dict[str, object]:
    """Process one raw 4x4 sprite sheet into strips, normalized 4x4 sheet, JSON, and GIFs."""
    out_dir.mkdir(parents=True, exist_ok=True)
    gifs_dir = out_dir / "gifs"
    gifs_dir.mkdir(parents=True, exist_ok=True)

    raw_img = Image.open(raw_path)
    clean_rgba = remove_chromakey_and_despill(raw_img)
    grid_rects = segment_4x4_cells(clean_rgba)

    cells: List[List[Image.Image]] = []
    metrics: List[List[Dict[str, float]]] = []
    row_baselines: List[float] = []
    for r in range(4):
        cell_row: List[Image.Image] = []
        met_row: List[Dict[str, float]] = []
        max_bottom = 0.0
        for c in range(4):
            crop = clean_rgba.crop(grid_rects[r][c])
            m = measure_foreground_metrics(crop)
            cell_row.append(crop)
            met_row.append(m)
            max_bottom = max(max_bottom, m["max_y"] + 1.0)
        cells.append(cell_row)
        metrics.append(met_row)
        row_baselines.append(max_bottom)

    cut_frames: Dict[Tuple[int, int, bool], Image.Image] = {}
    all_frames: List[Image.Image] = []
    for d in DIRECTIONS:
        for r, c, flip in DIRECTION_MAP[d]:
            key = (r, c, flip)
            if key in cut_frames:
                continue
            m = metrics[r][c]
            frame = downsample_crisp_cell(cells[r][c], global_scale, m["cx"], row_baselines[r])
            if flip:
                frame = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            cut_frames[key] = frame
            all_frames.append(frame)

    unique_colors = deduplicate_palette(all_frames)

    sheet = Image.new("RGBA", (CELL_SIZE * 4, CELL_SIZE * 4), (0, 0, 0, 0))
    anims_meta: Dict[str, Dict[str, object]] = {}
    for r_idx, d in enumerate(DIRECTIONS):
        walk_seq = [cut_frames[spec] for spec in DIRECTION_MAP[d]]
        idle_frame = walk_seq[0]

        idle_file = f"huwag_idle_{d}.png"
        idle_frame.save(out_dir / idle_file)
        anims_meta[f"idle_{d}"] = {"file": idle_file, "frames": 1, "fps": WALK_FPS, "loop": False}

        walk_strip = Image.new("RGBA", (CELL_SIZE * 4, CELL_SIZE), (0, 0, 0, 0))
        for col, frm in enumerate(walk_seq):
            walk_strip.paste(frm, (col * CELL_SIZE, 0))
            sheet.paste(frm, (col * CELL_SIZE, r_idx * CELL_SIZE))

        walk_file = f"huwag_walk_{d}.png"
        walk_strip.save(out_dir / walk_file)
        anims_meta[f"walk_{d}"] = {"file": walk_file, "frames": 4, "fps": WALK_FPS, "loop": True}

        gif_file = gifs_dir / f"huwag_walk_{d}.gif"
        save_transparent_gif(walk_seq, gif_file, scale=2)

    sheet_file = f"huwag_{outfit}_sheet_96x96.png"
    sheet.save(out_dir / sheet_file)

    atlas = {
        "character": "Huwag",
        "outfit": outfit,
        "cell_size": [CELL_SIZE, CELL_SIZE],
        "foot_anchor": [FOOT_ANCHOR_X, FOOT_ANCHOR_Y],
        "target_height_px": TARGET_CHAR_HEIGHT,
        "scale_from_raw": round(global_scale, 6),
        "unique_palette_colors": unique_colors,
        "sheet_file": sheet_file,
        "animations": anims_meta,
    }
    (out_dir / "huwag_atlas.json").write_text(json.dumps(atlas, indent=2), encoding="utf-8")
    return atlas


def compute_reference_scale(raw_paths: Sequence[Path]) -> float:
    """Compute a single uniform scale locked to standing sprite height across outfits."""
    heights: List[float] = []
    for p in raw_paths:
        rgba = remove_chromakey_and_despill(Image.open(p))
        grid = segment_4x4_cells(rgba)
        m = measure_foreground_metrics(rgba.crop(grid[0][0]))
        heights.append(m["height"])
    ref_height = sum(heights) / max(1, len(heights))
    return TARGET_CHAR_HEIGHT / max(1.0, ref_height)


def main() -> None:
    parser = argparse.ArgumentParser(description="Process Huwag v2 4x4 sprite sheets.")
    parser.add_argument(
        "--base-dir",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "assets" / "sprites" / "huwag_v2",
        help="Path to assets/sprites/huwag_v2 directory.",
    )
    args = parser.parse_args()

    raw_bombeiro = args.base_dir / "raw" / "huwag_bombeiro_raw_v5.jpg"
    raw_casual = args.base_dir / "raw" / "huwag_casual_raw_v1.jpg"
    global_scale = compute_reference_scale([raw_bombeiro, raw_casual])

    process_outfit(raw_bombeiro, args.base_dir / "bombeiro", "bombeiro", global_scale)
    process_outfit(raw_casual, args.base_dir / "casual", "casual", global_scale)
    print(f"Processed huwag_v2 bombeiro + casual cleanly at uniform scale {global_scale:.5f}.")


if __name__ == "__main__":
    main()

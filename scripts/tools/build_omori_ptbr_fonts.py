#!/usr/bin/env python3
"""
Gera fontes TrueType vetoriais completas para PT-BR e símbolos de UI
a partir de OMORI_GAME2.ttf e OMORI_GAME.ttf (sem dependências externas).

Preserva 100% dos glifos originais (contornos, métricas, kerning/advance)
e sintetiza glifos vetoriais nativos na tabela `glyf` com a mesma espessura
de traço (42 unidades / raio 21) e estética desenhada à mão para toda a
acentuação em português e símbolos usados em Huwag.
"""

import math
import os
import struct
import sys


# ---------------------------------------------------------------------------
# Utilitários de geometria vetorial (contornos TrueType CW = sólido, CCW = furo)
# ---------------------------------------------------------------------------

def signed_area(pts):
    area = 0.0
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i][0], pts[i][1]
        x2, y2 = pts[(i + 1) % n][0], pts[(i + 1) % n][1]
        area += x1 * y2 - x2 * y1
    return area


def ensure_winding(pts, clockwise=True):
    a = signed_area(pts)
    if clockwise and a > 0:
        return list(reversed(pts))
    if (not clockwise) and a < 0:
        return list(reversed(pts))
    return pts


def transform_contour(pts, sx=1.0, sy=1.0, dx=0.0, dy=0.0, flip_x=False, flip_y=False):
    was_cw = signed_area(pts) < 0
    out = []
    for x, y, on in pts:
        nx = (-x if flip_x else x) * sx + dx
        ny = (-y if flip_y else y) * sy + dy
        out.append((int(round(nx)), int(round(ny)), on))
    # Preserva orientação original (CW/CCW) após reflexão
    return ensure_winding(out, clockwise=was_cw)


def contours_bbox(contours):
    xs = [p[0] for c in contours for p in c]
    ys = [p[1] for c in contours for p in c]
    if not xs:
        return (0, 0, 0, 0)
    return (min(xs), min(ys), max(xs), max(ys))


def shift_contours(contours, dx, dy):
    dx = int(round(dx))
    dy = int(round(dy))
    return [[(x + dx, y + dy, on) for (x, y, on) in c] for c in contours]


def make_circle_contour(cx, cy, r, n=8, clockwise=True):
    pts = []
    for i in range(n):
        # CW em coordenadas Y-para-cima = ângulo decrescente
        ang = -2.0 * math.pi * i / n if clockwise else 2.0 * math.pi * i / n
        pts.append((int(round(cx + r * math.cos(ang))), int(round(cy + r * math.sin(ang))), True))
    return ensure_winding(pts, clockwise=clockwise)


def make_capsule(p0, p1, r=21.0, cap_segs=4):
    """Segmento reto com pontas arredondadas (mesmo estilo do traço da OMORI_GAME2)."""
    x0, y0 = p0
    x1, y1 = p1
    vx, vy = x1 - x0, y1 - y0
    dist = math.hypot(vx, vy)
    if dist < 1e-3:
        return make_circle_contour(x0, y0, r, n=8, clockwise=True)
    ang = math.atan2(vy, vx)
    pts = []
    # Semicírculo em p1 (de ang + pi/2 até ang - pi/2, sentido horário)
    for i in range(cap_segs + 1):
        a = ang + math.pi * 0.5 - math.pi * (i / cap_segs)
        pts.append((int(round(x1 + r * math.cos(a))), int(round(y1 + r * math.sin(a))), True))
    # Semicírculo em p0 (de ang - pi/2 até ang - 3*pi/2, sentido horário)
    for i in range(cap_segs + 1):
        a = ang - math.pi * 0.5 - math.pi * (i / cap_segs)
        pts.append((int(round(x0 + r * math.cos(a))), int(round(y0 + r * math.sin(a))), True))
    # Remove pontos duplicados consecutivos
    clean = []
    for pt in pts:
        if not clean or (pt[0] != clean[-1][0] or pt[1] != clean[-1][1]):
            clean.append(pt)
    if len(clean) > 1 and clean[0][:2] == clean[-1][:2]:
        clean.pop()
    return ensure_winding(clean, clockwise=True)


def make_stroke_polyline(spine, r=21.0, cap_segs=4):
    """
    Expande uma polilinha aberta suave em um único contorno CW sem auto-interseção,
    com pontas arredondadas (estilo caneta manual da fonte OMORI).
    """
    if len(spine) < 2:
        return make_circle_contour(spine[0][0], spine[0][1], r, n=8, clockwise=True)
    if len(spine) == 2:
        return make_capsule(spine[0], spine[1], r=r, cap_segs=cap_segs)

    # Calcula tangentes normalizadas em cada vértice
    tangents = []
    for i in range(len(spine)):
        if i == 0:
            dx = spine[1][0] - spine[0][0]
            dy = spine[1][1] - spine[0][1]
        elif i == len(spine) - 1:
            dx = spine[-1][0] - spine[-2][0]
            dy = spine[-1][1] - spine[-2][1]
        else:
            dx1 = spine[i][0] - spine[i - 1][0]
            dy1 = spine[i][1] - spine[i - 1][1]
            l1 = math.hypot(dx1, dy1) or 1.0
            dx2 = spine[i + 1][0] - spine[i][0]
            dy2 = spine[i + 1][1] - spine[i][1]
            l2 = math.hypot(dx2, dy2) or 1.0
            dx = dx1 / l1 + dx2 / l2
            dy = dy1 / l1 + dy2 / l2
            if math.hypot(dx, dy) < 1e-4:
                dx, dy = dx1 / l1, dy1 / l1
        length = math.hypot(dx, dy) or 1.0
        tangents.append((dx / length, dy / length))

    left_side = []
    right_side = []
    for i, (px, py) in enumerate(spine):
        tx, ty = tangents[i]
        # Normal à esquerda (-ty, tx) e à direita (ty, -tx)
        nx, ny = -ty, tx
        # Fator de miter limitado para evitar pontas agudas em curvas acentuadas
        scale = 1.0
        if 0 < i < len(spine) - 1:
            dx1 = spine[i][0] - spine[i - 1][0]
            dy1 = spine[i][1] - spine[i - 1][1]
            l1 = math.hypot(dx1, dy1) or 1.0
            n1x, n1y = -dy1 / l1, dx1 / l1
            dot = max(0.55, n1x * nx + n1y * ny)
            scale = min(1.35, 1.0 / dot)
        left_side.append((px + nx * r * scale, py + ny * r * scale))
        right_side.append((px - nx * r * scale, py - ny * r * scale))

    pts = []
    # Lado esquerdo do início ao fim
    for px, py in left_side:
        pts.append((int(round(px)), int(round(py)), True))

    # Ponta arredondada no final
    end_ang = math.atan2(tangents[-1][1], tangents[-1][0])
    for k in range(1, cap_segs):
        a = end_ang + math.pi * 0.5 - math.pi * (k / cap_segs)
        pts.append((int(round(spine[-1][0] + r * math.cos(a))), int(round(spine[-1][1] + r * math.sin(a))), True))

    # Lado direito do fim ao início
    for px, py in reversed(right_side):
        pts.append((int(round(px)), int(round(py)), True))

    # Ponta arredondada no início
    start_ang = math.atan2(tangents[0][1], tangents[0][0])
    for k in range(1, cap_segs):
        a = start_ang - math.pi * 0.5 - math.pi * (k / cap_segs)
        pts.append((int(round(spine[0][0] + r * math.cos(a))), int(round(spine[0][1] + r * math.sin(a))), True))

    clean = []
    for pt in pts:
        if not clean or (pt[0] != clean[-1][0] or pt[1] != clean[-1][1]):
            clean.append(pt)
    if len(clean) > 1 and clean[0][:2] == clean[-1][:2]:
        clean.pop()
    return ensure_winding(clean, clockwise=True)


# ---------------------------------------------------------------------------
# Parser e Encoder TrueType (SFNT / glyf / loca / hmtx / cmap / head / hhea / maxp / OS/2 / name / post)
# ---------------------------------------------------------------------------

def calc_checksum(data):
    padded = data + b'\x00' * ((4 - (len(data) % 4)) % 4)
    total = 0
    for i in range(0, len(padded), 4):
        total = (total + struct.unpack('>I', padded[i:i + 4])[0]) & 0xFFFFFFFF
    return total


def parse_ttf(path):
    with open(path, 'rb') as f:
        data = f.read()
    sfnt, num_tables = struct.unpack('>IH', data[:6])
    tables = {}
    for i in range(num_tables):
        off = 12 + i * 16
        tag, csum, toff, tlen = struct.unpack('>4sIII', data[off:off + 16])
        tables[tag.decode('ascii')] = data[toff:toff + tlen]
    return sfnt, tables


def decode_cmap_format4(cmap_bytes):
    _, nsub = struct.unpack('>HH', cmap_bytes[:4])
    for i in range(nsub):
        pid, eid, suboff = struct.unpack('>HHI', cmap_bytes[4 + i * 8:12 + i * 8])
        fmt = struct.unpack('>H', cmap_bytes[suboff:suboff + 2])[0]
        if fmt == 4:
            so = suboff
            seg_count = struct.unpack('>H', cmap_bytes[so + 6:so + 8])[0] // 2
            end_codes = struct.unpack(f'>{seg_count}H', cmap_bytes[so + 14:so + 14 + seg_count * 2])
            start_off = so + 16 + seg_count * 2
            start_codes = struct.unpack(f'>{seg_count}H', cmap_bytes[start_off:start_off + seg_count * 2])
            delta_off = start_off + seg_count * 2
            id_deltas = struct.unpack(f'>{seg_count}h', cmap_bytes[delta_off:delta_off + seg_count * 2])
            range_off = delta_off + seg_count * 2
            id_range_offsets = struct.unpack(f'>{seg_count}H', cmap_bytes[range_off:range_off + seg_count * 2])
            mapping = {}
            for s in range(seg_count):
                sc, ec, dl, ro = start_codes[s], end_codes[s], id_deltas[s], id_range_offsets[s]
                if sc == 0xFFFF:
                    continue
                for cp in range(sc, ec + 1):
                    if ro == 0:
                        gid = (cp + dl) & 0xFFFF
                    else:
                        addr = range_off + s * 2 + ro + (cp - sc) * 2
                        gid = struct.unpack('>H', cmap_bytes[addr:addr + 2])[0]
                        if gid != 0:
                            gid = (gid + dl) & 0xFFFF
                    if gid != 0:
                        mapping[cp] = gid
            return mapping
    raise ValueError("Nenhuma subtable cmap format 4 encontrada")


def encode_cmap_format4(mapping):
    """Gera tabela cmap completa com subtables (0, 3) e (3, 1) apontando para o mesmo Format 4."""
    items = sorted((cp, gid) for cp, gid in mapping.items() if 0 <= cp <= 0xFFFE and gid > 0)
    segments = []
    for cp, gid in items:
        delta = (gid - cp) & 0xFFFF
        if segments and segments[-1][1] + 1 == cp and segments[-1][2] == delta:
            segments[-1] = (segments[-1][0], cp, delta)
        else:
            segments.append((cp, cp, delta))
    segments.append((0xFFFF, 0xFFFF, 1))

    seg_count = len(segments)
    seg_count_x2 = seg_count * 2
    entry_selector = int(math.floor(math.log2(seg_count)))
    search_range = 2 * (1 << entry_selector)
    range_shift = seg_count_x2 - search_range

    end_codes = b''.join(struct.pack('>H', s[1]) for s in segments)
    start_codes = b''.join(struct.pack('>H', s[0]) for s in segments)
    id_deltas = b''.join(struct.pack('>H', s[2]) for s in segments)
    id_range_offsets = b'\x00\x00' * seg_count

    sub_body = (
        struct.pack('>HHHHHH', seg_count_x2, search_range, entry_selector, range_shift, 0, 0)[:8]
        + end_codes
        + b'\x00\x00'  # reservedPad
        + start_codes
        + id_deltas
        + id_range_offsets
    )
    sub_len = 6 + len(sub_body)
    subtable = struct.pack('>HHH', 4, sub_len, 0) + sub_body

    # Header cmap: version=0, numTables=2 -> (0,3) e (3,1) apontam para offset 20
    header = struct.pack('>HH', 0, 2)
    rec0 = struct.pack('>HHI', 0, 3, 20)
    rec1 = struct.pack('>HHI', 3, 1, 20)
    return header + rec0 + rec1 + subtable


def decode_simple_glyph(glyf_bytes, start, end):
    if start == end:
        return []
    nc, x0, y0, x1, y1 = struct.unpack('>hhhhh', glyf_bytes[start:start + 10])
    if nc < 0:
        raise ValueError("Glifo composto inesperado no arquivo base")
    pos = start + 10
    end_pts = list(struct.unpack(f'>{nc}H', glyf_bytes[pos:pos + nc * 2]))
    pos += nc * 2
    inst_len = struct.unpack('>H', glyf_bytes[pos:pos + 2])[0]
    pos += 2 + inst_len
    npts = end_pts[-1] + 1
    flags = []
    while len(flags) < npts:
        fl = glyf_bytes[pos]
        pos += 1
        flags.append(fl)
        if fl & 0x08:
            rep = glyf_bytes[pos]
            pos += 1
            flags.extend([fl] * rep)
    xs = []
    x = 0
    for fl in flags:
        if fl & 0x02:
            dx = glyf_bytes[pos]
            pos += 1
            x += dx if (fl & 0x10) else -dx
        elif not (fl & 0x10):
            dx = struct.unpack('>h', glyf_bytes[pos:pos + 2])[0]
            pos += 2
            x += dx
        xs.append(x)
    ys = []
    y = 0
    for fl in flags:
        if fl & 0x04:
            dy = glyf_bytes[pos]
            pos += 1
            y += dy if (fl & 0x20) else -dy
        elif not (fl & 0x20):
            dy = struct.unpack('>h', glyf_bytes[pos:pos + 2])[0]
            pos += 2
            y += dy
        ys.append(y)
    contours = []
    s = 0
    for e in end_pts:
        contours.append([(xs[k], ys[k], bool(flags[k] & 1)) for k in range(s, e + 1)])
        s = e + 1
    return contours


def encode_simple_glyph(contours):
    if not contours:
        return b'', (0, 0, 0, 0), 0, 0
    x0, y0, x1, y1 = contours_bbox(contours)
    nc = len(contours)
    end_pts = []
    flat = []
    for c in contours:
        flat.extend(c)
        end_pts.append(len(flat) - 1)

    flags = bytearray()
    x_bytes = bytearray()
    y_bytes = bytearray()
    px, py = 0, 0
    for (x, y, on) in flat:
        fl = 0x01 if on else 0x00
        dx = x - px
        dy = y - py
        px, py = x, y
        if dx == 0:
            fl |= 0x10
        elif -255 <= dx <= 255:
            fl |= 0x02
            if dx > 0:
                fl |= 0x10
            x_bytes.append(abs(dx))
        else:
            x_bytes.extend(struct.pack('>h', dx))
        if dy == 0:
            fl |= 0x20
        elif -255 <= dy <= 255:
            fl |= 0x04
            if dy > 0:
                fl |= 0x20
            y_bytes.append(abs(dy))
        else:
            y_bytes.extend(struct.pack('>h', dy))
        flags.append(fl)

    out = bytearray()
    out.extend(struct.pack('>hhhhh', nc, x0, y0, x1, y1))
    for ep in end_pts:
        out.extend(struct.pack('>H', ep))
    out.extend(struct.pack('>H', 0))  # instructionLength = 0
    out.extend(flags)
    out.extend(x_bytes)
    out.extend(y_bytes)
    # Pad para múltiplo de 4 bytes
    while len(out) % 4 != 0:
        out.append(0)
    return bytes(out), (x0, y0, x1, y1), len(flat), nc


def build_name_table(family_name, full_name, ps_name, copyright_str):
    records_spec = [
        (0, copyright_str),
        (1, family_name),
        (2, "Regular"),
        (3, f"{ps_name};PTBR"),
        (4, full_name),
        (5, "Version 3.0 PT-BR Vector"),
        (6, ps_name),
    ]
    recs = []
    str_blob = bytearray()
    # Platform 1 (Mac Roman) + Platform 3 (Windows UTF-16BE)
    for pid, eid, lid, enc in [(1, 0, 0, 'latin-1'), (3, 1, 0x0409, 'utf-16-be')]:
        for nid, text in records_spec:
            raw = text.encode(enc, 'replace')
            off = len(str_blob)
            str_blob.extend(raw)
            recs.append((pid, eid, lid, nid, len(raw), off))
    recs.sort(key=lambda r: (r[0], r[1], r[2], r[3]))
    str_offset = 6 + len(recs) * 12
    out = bytearray(struct.pack('>HHH', 0, len(recs), str_offset))
    for r in recs:
        out.extend(struct.pack('>HHHHHH', *r))
    out.extend(str_blob)
    return bytes(out)


# ---------------------------------------------------------------------------
# Síntese artística dos diacríticos e símbolos no estilo exato da fonte OMORI
# ---------------------------------------------------------------------------

def build_extended_font(src_path, dst_path, family_name, ps_name, is_title_font=False):
    sfnt, tables = parse_ttf(src_path)
    head = bytearray(tables['head'])
    hhea = bytearray(tables['hhea'])
    maxp = bytearray(tables['maxp'])
    os2 = bytearray(tables['OS/2'])
    post = bytearray(tables['post'])
    hmtx = tables['hmtx']
    loca = tables['loca']
    glyf = tables['glyf']
    cmap_map = decode_cmap_format4(tables['cmap'])

    num_glyphs = struct.unpack('>H', maxp[4:6])[0]
    idx_loc_fmt = struct.unpack('>h', head[50:52])[0]
    num_hmetrics = struct.unpack('>H', hhea[34:36])[0]

    if idx_loc_fmt == 0:
        orig_locas = [v * 2 for v in struct.unpack(f'>{num_glyphs + 1}H', loca[:(num_glyphs + 1) * 2])]
    else:
        orig_locas = list(struct.unpack(f'>{num_glyphs + 1}I', loca[:(num_glyphs + 1) * 4]))

    # Extrai todos os glifos originais (raw bytes + hmtx)
    raw_glyphs = []
    hmtx_list = []
    last_aw = struct.unpack('>H', hmtx[(num_hmetrics - 1) * 4:(num_hmetrics - 1) * 4 + 2])[0]
    for gid in range(num_glyphs):
        g_raw = glyf[orig_locas[gid]:orig_locas[gid + 1]]
        if len(g_raw) % 4 != 0:
            g_raw = g_raw + b'\x00' * (4 - (len(g_raw) % 4))
        raw_glyphs.append(g_raw)
        if gid < num_hmetrics:
            aw, lsb = struct.unpack('>Hh', hmtx[gid * 4:gid * 4 + 4])
        else:
            lsb = struct.unpack('>h', hmtx[num_hmetrics * 4 + (gid - num_hmetrics) * 2:num_hmetrics * 4 + (gid - num_hmetrics) * 2 + 2])[0]
            aw = last_aw
        hmtx_list.append((aw, lsb))

    # Helpers para ler contornos de qualquer caractere existente
    def get_char_data(ch):
        gid = cmap_map[ord(ch)]
        contours = decode_simple_glyph(glyf, orig_locas[gid], orig_locas[gid + 1])
        aw, lsb = hmtx_list[gid]
        bbox = contours_bbox(contours)
        return contours, aw, lsb, bbox

    # Extrai traços-base originais da própria fonte OMORI!
    grave_c, _, _, grave_bb = get_char_data('`')
    caret_c, _, _, caret_bb = get_char_data('^')
    tilde_c, _, _, tilde_bb = get_char_data('~')
    i_c, i_aw, i_lsb, i_bb = get_char_data('i')
    dot_c, _, _, dot_bb = get_char_data('.')
    o_c, o_aw, _, o_bb = get_char_data('o')
    a_c, a_aw, _, a_bb = get_char_data('a')

    # Em OMORI_GAME2 e OMORI_GAME, i_c[0] é o pingo (menor y-span no topo) e i_c[1] é a haste!
    i_sorted = sorted(i_c, key=lambda c: contours_bbox([c])[1])
    dotless_i_contours = [i_sorted[0]]  # haste (y mais baixo)
    i_dot_contour = i_sorted[-1]        # pingo (y mais alto)

    # Normaliza cada diacrítico para centro horizontal X=0 e base Y=0
    def normalize_mark(contours, sx=1.0, sy=1.0, flip_x=False):
        t = [transform_contour(c, sx=sx, sy=sy, flip_x=flip_x) for c in contours]
        x0, y0, x1, y1 = contours_bbox(t)
        cx = (x0 + x1) * 0.5
        return shift_contours(t, -cx, -y0)

    # Raio de traço da fonte (21 em OMORI_GAME2; ~24 em OMORI_GAME)
    stroke_r = 24.0 if is_title_font else 21.0

    # Diacríticos nativos derivados dos próprios traços da OMORI:
    # - Grave (`): traço original da fonte (`), levemente refinado para escala de acento
    # - Agudo (´): espelhamento horizontal do grave original (mesmo ângulo e espessura manual!)
    # - Circunflexo (^): traço `^` original ajustado proporcionalmente
    # - Til (~): traço `~` original ajustado para caber confortavelmente sobre A/O/a/o/N/n
    # - Trema (¨): dois pingos originais do 'i' lado a lado
    if not is_title_font:
        mark_grave_up = normalize_mark(grave_c, sx=0.92, sy=0.92, flip_x=False)
        mark_acute_up = normalize_mark(grave_c, sx=0.92, sy=0.92, flip_x=True)
        mark_grave_lo = normalize_mark(grave_c, sx=0.86, sy=0.86, flip_x=False)
        mark_acute_lo = normalize_mark(grave_c, sx=0.86, sy=0.86, flip_x=True)
        mark_circ_up = normalize_mark(caret_c, sx=0.92, sy=0.78)
        mark_circ_lo = normalize_mark(caret_c, sx=0.84, sy=0.72)
        mark_tilde_up = normalize_mark(tilde_c, sx=0.74, sy=0.84)
        mark_tilde_lo = normalize_mark(tilde_c, sx=0.68, sy=0.80)
        mark_acute_i = normalize_mark(grave_c, sx=0.76, sy=0.82, flip_x=True)
        mark_grave_i = normalize_mark(grave_c, sx=0.76, sy=0.82, flip_x=False)
        mark_circ_i = normalize_mark(caret_c, sx=0.70, sy=0.66)
    else:
        # OMORI_GAME.ttf tem letras maiúsculas mais altas (~600); acentos ligeiramente compactos
        mark_grave_up = normalize_mark(grave_c, sx=1.05, sy=0.92, flip_x=False)
        mark_acute_up = normalize_mark(grave_c, sx=1.05, sy=0.92, flip_x=True)
        mark_grave_lo = normalize_mark(grave_c, sx=0.96, sy=0.88, flip_x=False)
        mark_acute_lo = normalize_mark(grave_c, sx=0.96, sy=0.88, flip_x=True)
        mark_circ_up = normalize_mark(caret_c, sx=0.58, sy=0.52)
        mark_circ_lo = normalize_mark(caret_c, sx=0.52, sy=0.48)
        mark_tilde_up = normalize_mark(tilde_c, sx=0.62, sy=0.62)
        mark_tilde_lo = normalize_mark(tilde_c, sx=0.56, sy=0.58)
        mark_acute_i = normalize_mark(grave_c, sx=0.95, sy=0.85, flip_x=True)
        mark_grave_i = normalize_mark(grave_c, sx=0.95, sy=0.85, flip_x=False)
        mark_circ_i = normalize_mark(caret_c, sx=0.45, sy=0.45)

    # Trema (¨): dois pingos no estilo do pingo do 'i'
    dot_r = 24.0 if is_title_font else 23.0
    mark_dier_up = [
        make_circle_contour(-58, dot_r, dot_r, n=8, clockwise=True),
        make_circle_contour(58, dot_r, dot_r, n=8, clockwise=True),
    ]
    mark_dier_lo = [
        make_circle_contour(-52, dot_r, dot_r, n=8, clockwise=True),
        make_circle_contour(52, dot_r, dot_r, n=8, clockwise=True),
    ]
    mark_dier_i = [
        make_circle_contour(-44, dot_r * 0.92, dot_r * 0.92, n=8, clockwise=True),
        make_circle_contour(44, dot_r * 0.92, dot_r * 0.92, n=8, clockwise=True),
    ]

    # Cedilha (¸): gancho orgânico desenhado à mão preso suavemente na base do C/c
    def make_cedilla(attach_x, attach_y, scale=1.0):
        # Começa levemente sobreposto na base inferior do C/c para conexão sem falhas
        spine = [
            (attach_x + 4 * scale, attach_y + 12 * scale),
            (attach_x + 0 * scale, attach_y - 34 * scale),
            (attach_x + 42 * scale, attach_y - 54 * scale),
            (attach_x + 56 * scale, attach_y - 92 * scale),
            (attach_x + 28 * scale, attach_y - 122 * scale),
            (attach_x - 24 * scale, attach_y - 122 * scale),
            (attach_x - 44 * scale, attach_y - 108 * scale),
        ]
        return [make_stroke_polyline(spine, r=stroke_r * (0.90 if scale < 1.0 else 0.95), cap_segs=4)]

    # Estado para novos glifos
    new_max_pts = struct.unpack('>H', maxp[6:8])[0]
    new_max_cnt = struct.unpack('>H', maxp[8:10])[0]
    font_xmin, font_ymin, font_xmax, font_ymax = struct.unpack('>hhhh', head[36:44])

    def add_glyph(cp, contours, advance_width):
        nonlocal new_max_pts, new_max_cnt, font_xmin, font_ymin, font_xmax, font_ymax
        g_bytes, (x0, y0, x1, y1), npts, ncnt = encode_simple_glyph(contours)
        gid = len(raw_glyphs)
        raw_glyphs.append(g_bytes)
        lsb = x0 if contours else 0
        hmtx_list.append((int(round(advance_width)), int(lsb)))
        cmap_map[cp] = gid
        if npts > new_max_pts:
            new_max_pts = npts
        if ncnt > new_max_cnt:
            new_max_cnt = ncnt
        if contours:
            font_xmin = min(font_xmin, x0)
            font_ymin = min(font_ymin, y0)
            font_xmax = max(font_xmax, x1)
            font_ymax = max(font_ymax, y1)
        return gid

    def compose_accented(cp, base_ch, mark_contours, gap_y=52, x_nudge=0, force_dotless_i=False, min_adv=None):
        if force_dotless_i:
            base_c = [list(c) for c in dotless_i_contours]
            base_aw = i_aw
            base_bb = contours_bbox(base_c)
        else:
            base_c, base_aw, _, base_bb = get_char_data(base_ch)

        # Centro visual superior da letra-base (média ponderada entre topo e centro do bbox)
        all_pts = [pt for c in base_c for pt in c]
        top_y = base_bb[3]
        near_top = [pt[0] for pt in all_pts if pt[1] >= top_y - 55]
        top_cx = (min(near_top) + max(near_top)) * 0.5 if near_top else (base_bb[0] + base_bb[2]) * 0.5
        bbox_cx = (base_bb[0] + base_bb[2]) * 0.5
        anchor_x = bbox_cx * 0.65 + top_cx * 0.35 + x_nudge
        anchor_y = top_y + gap_y

        placed_mark = shift_contours(mark_contours, anchor_x, anchor_y)
        combined = [list(c) for c in base_c] + placed_mark
        aw = base_aw
        # Para letras estreitas (como 'í', 'î', 'ï'), garante respiro mínimo sem invadir vizinhos
        comb_bb = contours_bbox(combined)
        if comb_bb[0] < 16:
            shift_x = 24 - comb_bb[0]
            combined = shift_contours(combined, shift_x, 0)
            comb_bb = contours_bbox(combined)
            aw = max(aw, comb_bb[2] + 24)
        if min_adv is not None:
            aw = max(aw, min_adv)
        if comb_bb[2] + 18 > aw and force_dotless_i:
            aw = comb_bb[2] + 22
        add_glyph(cp, combined, aw)

    # Gap vertical calibrado para cada fonte
    gap_up = 48 if not is_title_font else 38
    gap_lo = 46 if not is_title_font else 42
    gap_i = 58 if not is_title_font else 68

    # 1) Maiúsculas acentuadas (PT-BR completo + espanhol/francês comum)
    upper_specs = [
        ('Á', 'A', mark_acute_up, 0),
        ('À', 'A', mark_grave_up, 0),
        ('Â', 'A', mark_circ_up, 0),
        ('Ã', 'A', mark_tilde_up, 0),
        ('Ä', 'A', mark_dier_up, 0),
        ('É', 'E', mark_acute_up, -4),
        ('È', 'E', mark_grave_up, -4),
        ('Ê', 'E', mark_circ_up, -4),
        ('Ë', 'E', mark_dier_up, -4),
        ('Í', 'I', mark_acute_up, 0),
        ('Ì', 'I', mark_grave_up, 0),
        ('Î', 'I', mark_circ_up, 0),
        ('Ï', 'I', mark_dier_up, 0),
        ('Ó', 'O', mark_acute_up, 0),
        ('Ò', 'O', mark_grave_up, 0),
        ('Ô', 'O', mark_circ_up, 0),
        ('Õ', 'O', mark_tilde_up, 0),
        ('Ö', 'O', mark_dier_up, 0),
        ('Ú', 'U', mark_acute_up, -28 if is_title_font else 0),
        ('Ù', 'U', mark_grave_up, -28 if is_title_font else 0),
        ('Û', 'U', mark_circ_up, -28 if is_title_font else 0),
        ('Ü', 'U', mark_dier_up, -28 if is_title_font else 0),
        ('Ñ', 'N', mark_tilde_up, 0),
    ]
    for ch, base, mk, xn in upper_specs:
        compose_accented(ord(ch), base, mk, gap_y=gap_up, x_nudge=xn)

    # 2) Minúsculas acentuadas (com 'ı' sem pingo para í/ì/î/ï!)
    lower_specs = [
        ('á', 'a', mark_acute_lo, 0, False, None),
        ('à', 'a', mark_grave_lo, 0, False, None),
        ('â', 'a', mark_circ_lo, 0, False, None),
        ('ã', 'a', mark_tilde_lo, 0, False, None),
        ('ä', 'a', mark_dier_lo, 0, False, None),
        ('é', 'e', mark_acute_lo, 0, False, None),
        ('è', 'e', mark_grave_lo, 0, False, None),
        ('ê', 'e', mark_circ_lo, 0, False, None),
        ('ë', 'e', mark_dier_lo, 0, False, None),
        ('í', 'i', mark_acute_i, 0, True, 178 if not is_title_font else 232),
        ('ì', 'i', mark_grave_i, -10, True, 178 if not is_title_font else 232),
        ('î', 'i', mark_circ_i, 0, True, 204 if not is_title_font else 248),
        ('ï', 'i', mark_dier_i, 0, True, 194 if not is_title_font else 244),
        ('ó', 'o', mark_acute_lo, 0, False, None),
        ('ò', 'o', mark_grave_lo, 0, False, None),
        ('ô', 'o', mark_circ_lo, 0, False, None),
        ('õ', 'o', mark_tilde_lo, 0, False, None),
        ('ö', 'o', mark_dier_lo, 0, False, None),
        ('ú', 'u', mark_acute_lo, 0, False, None),
        ('ù', 'u', mark_grave_lo, 0, False, None),
        ('û', 'u', mark_circ_lo, 0, False, None),
        ('ü', 'u', mark_dier_lo, 0, False, None),
        ('ñ', 'n', mark_tilde_lo, 0, False, None),
    ]
    for ch, base, mk, xn, dotless, madv in lower_specs:
        compose_accented(ord(ch), base, mk, gap_y=(gap_i if dotless else gap_lo), x_nudge=xn, force_dotless_i=dotless, min_adv=madv)

    # 3) Ç e ç (cedilha desenhada à mão conectada à curva inferior de C e c)
    C_c, C_aw, _, C_bb = get_char_data('C')
    C_low = [p[0] for p in C_c[0] if p[1] <= C_bb[1] + 24]
    C_ced_x = (min(C_low) + max(C_low)) * 0.5 if C_low else (C_bb[0] + C_bb[2]) * 0.5
    add_glyph(ord('Ç'), [list(c) for c in C_c] + make_cedilla(C_ced_x, C_bb[1], scale=1.0), C_aw)

    c_c, c_aw, _, c_bb = get_char_data('c')
    c_low = [p[0] for p in c_c[0] if p[1] <= c_bb[1] + 24]
    c_ced_x = (min(c_low) + max(c_low)) * 0.5 if c_low else (c_bb[0] + c_bb[2]) * 0.5
    add_glyph(ord('ç'), [list(c) for c in c_c] + make_cedilla(c_ced_x, c_bb[1], scale=0.90), c_aw)

    # 4) Dotless i (U+0131) caso seja necessário
    add_glyph(0x0131, [list(c) for c in dotless_i_contours], i_aw)

    # 5) Símbolos tipográficos e de UI usados no projeto (PT-BR, menus, créditos, HUD)
    mid_y = 168 if not is_title_font else 280

    # · (U+00B7 middle dot — "Último registro · 06:30", "Agdangan, Quezon · Demo")
    add_glyph(0x00B7, [make_circle_contour(94, mid_y, 40 if not is_title_font else 48, n=8, clockwise=True)], 188)

    # • (U+2022 bullet — Créditos musicais)
    add_glyph(0x2022, [make_circle_contour(120, mid_y, 66 if not is_title_font else 76, n=10, clockwise=True)], 240)

    # — (U+2014 em dash — diálogos e créditos)
    add_glyph(0x2014, [make_capsule((40, mid_y), (460, mid_y), r=stroke_r)], 500)

    # … (U+2026 reticências — 3 pontos originais)
    d0 = shift_contours(dot_c, 0, 0)
    d_w = dot_bb[2] - dot_bb[0]
    step_d = max(115, d_w + 46)
    add_glyph(0x2026, d0 + shift_contours(dot_c, step_d, 0) + shift_contours(dot_c, step_d * 2, 0), dot_bb[2] + step_d * 2 + 36)

    # ° (U+00B0 grau)
    deg_y = 330 if not is_title_font else 510
    add_glyph(0x00B0, [
        make_circle_contour(110, deg_y, 68, n=12, clockwise=True),
        make_circle_contour(110, deg_y, 34, n=12, clockwise=False),
    ], 220)

    # º (U+00BA ordinal masculino) e ª (U+00AA ordinal feminino)
    o_small = [transform_contour(c, sx=0.58, sy=0.58) for c in o_c]
    o_sbb = contours_bbox(o_small)
    o_placed = shift_contours(o_small, 36 - o_sbb[0], (200 if not is_title_font else 360) - o_sbb[1])
    o_pbb = contours_bbox(o_placed)
    o_bar = [make_capsule((o_pbb[0] + 10, o_pbb[1] - 44), (o_pbb[2] - 10, o_pbb[1] - 44), r=16.0)]
    add_glyph(0x00BA, o_placed + o_bar, o_pbb[2] + 40)

    a_small = [transform_contour(c, sx=0.56, sy=0.56) for c in a_c]
    a_sbb = contours_bbox(a_small)
    a_placed = shift_contours(a_small, 36 - a_sbb[0], (200 if not is_title_font else 360) - a_sbb[1])
    a_pbb = contours_bbox(a_placed)
    a_bar = [make_capsule((a_pbb[0] + 10, a_pbb[1] - 44), (a_pbb[2] - 10, a_pbb[1] - 44), r=16.0)]
    add_glyph(0x00AA, a_placed + a_bar, a_pbb[2] + 40)

    # × (U+00D7 multiplicação) e ÷ (U+00F7 divisão)
    add_glyph(0x00D7, [
        make_capsule((64, mid_y - 96), (256, mid_y + 96), r=stroke_r),
        make_capsule((64, mid_y + 96), (256, mid_y - 96), r=stroke_r),
    ], 320)
    add_glyph(0x00F7, [
        make_capsule((52, mid_y), (268, mid_y), r=stroke_r),
        make_circle_contour(160, mid_y + 94, 28, n=8, clockwise=True),
        make_circle_contour(160, mid_y - 94, 28, n=8, clockwise=True),
    ], 320)

    # « » (U+00AB, U+00BB)
    add_glyph(0x00AB, [
        make_stroke_polyline([(148, mid_y + 84), (62, mid_y), (148, mid_y - 84)], r=18.0),
        make_stroke_polyline([(248, mid_y + 84), (162, mid_y), (248, mid_y - 84)], r=18.0),
    ], 300)
    add_glyph(0x00BB, [
        make_stroke_polyline([(62, mid_y + 84), (148, mid_y), (62, mid_y - 84)], r=18.0),
        make_stroke_polyline([(162, mid_y + 84), (248, mid_y), (162, mid_y - 84)], r=18.0),
    ], 300)

    # ► ◄ ▲ ▼ (U+25BA, U+25C4, U+25B2, U+25BC)
    add_glyph(0x25BA, [ensure_winding([(48, mid_y + 148, True), (296, mid_y, True), (48, mid_y - 148, True)], True)], 340)
    add_glyph(0x25C4, [ensure_winding([(292, mid_y + 148, True), (292, mid_y - 148, True), (44, mid_y, True)], True)], 340)
    add_glyph(0x25B2, [ensure_winding([(170, mid_y + 146, True), (312, mid_y - 108, True), (28, mid_y - 108, True)], True)], 340)
    add_glyph(0x25BC, [ensure_winding([(28, mid_y + 108, True), (312, mid_y + 108, True), (170, mid_y - 146, True)], True)], 340)

    # ● (U+25CF) e ■ (U+25A0)
    add_glyph(0x25CF, [make_circle_contour(150, mid_y, 108, n=14, clockwise=True)], 300)
    add_glyph(0x25A0, [ensure_winding([(46, mid_y - 102, True), (46, mid_y + 102, True), (254, mid_y + 102, True), (254, mid_y - 102, True)], True)], 300)

    # ↑ ↓ ← → (U+2191, U+2193, U+2190, U+2192 — prompts de teclado)
    ar = 19.0
    add_glyph(0x2191, [
        make_capsule((140, mid_y - 135), (140, mid_y + 135), r=ar),
        make_stroke_polyline([(66, mid_y + 58), (140, mid_y + 142), (214, mid_y + 58)], r=ar),
    ], 280)
    add_glyph(0x2193, [
        make_capsule((140, mid_y + 135), (140, mid_y - 135), r=ar),
        make_stroke_polyline([(66, mid_y - 58), (140, mid_y - 142), (214, mid_y - 58)], r=ar),
    ], 280)
    add_glyph(0x2190, [
        make_capsule((54, mid_y), (304, mid_y), r=ar),
        make_stroke_polyline([(132, mid_y + 74), (48, mid_y), (132, mid_y - 74)], r=ar),
    ], 350)
    add_glyph(0x2192, [
        make_capsule((46, mid_y), (296, mid_y), r=ar),
        make_stroke_polyline([(218, mid_y + 74), (302, mid_y), (218, mid_y - 74)], r=ar),
    ], 350)

    # Acertos avulsos espaçados úteis: ´ (U+00B4), ¨ (U+00A8), ¸ (U+00B8), NBSP (U+00A0)
    sp_aw = hmtx_list[cmap_map[ord(' ')]][0]
    add_glyph(0x00A0, [], sp_aw)
    add_glyph(0x00B4, shift_contours(mark_acute_up, 95, 480 if not is_title_font else 540), 190)
    add_glyph(0x00A8, shift_contours(mark_dier_up, 110, 480 if not is_title_font else 540), 220)
    add_glyph(0x00B8, make_cedilla(95, 0, scale=0.95), 190)

    # -----------------------------------------------------------------------
    # Remontagem das tabelas TrueType
    # -----------------------------------------------------------------------
    final_num_glyphs = len(raw_glyphs)

    # glyf + loca (formato 1 = uint32)
    new_glyf = bytearray()
    new_loca = bytearray()
    for g in raw_glyphs:
        new_loca.extend(struct.pack('>I', len(new_glyf)))
        new_glyf.extend(g)
    new_loca.extend(struct.pack('>I', len(new_glyf)))

    # hmtx
    new_hmtx = bytearray()
    adv_max = 0
    min_lsb = 32767
    min_rsb = 32767
    xmax_ext = -32768
    adv_sum = 0
    adv_cnt = 0
    for gid, (aw, lsb) in enumerate(hmtx_list):
        new_hmtx.extend(struct.pack('>Hh', aw, lsb))
        adv_max = max(adv_max, aw)
        if aw > 0:
            adv_sum += aw
            adv_cnt += 1
        g = raw_glyphs[gid]
        if len(g) >= 10:
            _, gx0, _, gx1, _ = struct.unpack('>hhhhh', g[:10])
            min_lsb = min(min_lsb, lsb)
            rsb = aw - (lsb + (gx1 - gx0))
            min_rsb = min(min_rsb, rsb)
            xmax_ext = max(xmax_ext, lsb + (gx1 - gx0))

    # head: zera checkSumAdjustment, atualiza bbox e indexToLocFormat=1
    struct.pack_into('>I', head, 8, 0)
    struct.pack_into('>hhhh', head, 36, font_xmin, font_ymin, font_xmax, font_ymax)
    struct.pack_into('>h', head, 50, 1)

    # hhea: atualiza métricas horizontais + numberOfHMetrics
    # (mantém ascender/descender/lineGap originais intactos para preservar altura de linha!)
    struct.pack_into('>Hhhh', hhea, 10, adv_max, min_lsb, min_rsb, xmax_ext)
    struct.pack_into('>H', hhea, 34, final_num_glyphs)

    # maxp
    struct.pack_into('>HHH', maxp, 4, final_num_glyphs, new_max_pts, new_max_cnt)

    # OS/2
    avg_w = int(round(adv_sum / max(1, adv_cnt)))
    struct.pack_into('>h', os2, 2, avg_w)
    # Unicode ranges: Basic Latin (0), Latin-1 Supp (1), Latin Ext-A (2), General Punctuation (31), Arrows (37), Geometric Shapes (45)
    r1, r2, r3, r4 = struct.unpack('>IIII', os2[42:58])
    r1 |= (1 << 0) | (1 << 1) | (1 << 2) | (1 << 31)
    r2 |= (1 << (37 - 32)) | (1 << (45 - 32))
    struct.pack_into('>IIII', os2, 42, r1, r2, r3, r4)
    min_cp = min(cmap_map.keys())
    max_cp = min(0xFFFF, max(cmap_map.keys()))
    struct.pack_into('>HH', os2, 64, min_cp, max_cp)
    # Atualiza winAscent / winDescent apenas se algum novo glifo ultrapassar o limite
    cur_win_asc, cur_win_desc = struct.unpack('>HH', os2[74:78])
    new_win_asc = max(cur_win_asc, max(0, font_ymax))
    new_win_desc = max(cur_win_desc, max(0, -font_ymin))
    struct.pack_into('>HH', os2, 74, new_win_asc, new_win_desc)

    # post v3.0 (32 bytes, sem tabela de nomes obsoleta)
    new_post = bytearray(post[:32])
    struct.pack_into('>I', new_post, 0, 0x00030000)

    # cmap
    new_cmap = encode_cmap_format4(cmap_map)

    # name
    new_name = build_name_table(
        family_name=family_name,
        full_name=family_name,
        ps_name=ps_name,
        copyright_str="OMORI (c) OMOCAT, LLC — Extensão vetorial PT-BR para projeto Huwag",
    )

    out_tables = {
        'OS/2': bytes(os2),
        'cmap': new_cmap,
        'glyf': bytes(new_glyf),
        'head': bytes(head),
        'hhea': bytes(hhea),
        'hmtx': bytes(new_hmtx),
        'loca': bytes(new_loca),
        'maxp': bytes(maxp),
        'name': new_name,
        'post': bytes(new_post),
    }
    if 'gasp' in tables:
        out_tables['gasp'] = tables['gasp']

    # Monta o binário SFNT ordenado alfabeticamente por tag
    tags = sorted(out_tables.keys())
    nt = len(tags)
    es = int(math.floor(math.log2(nt)))
    sr = 16 * (1 << es)
    rs = nt * 16 - sr

    header = struct.pack('>IHHHH', sfnt, nt, sr, es, rs)
    offset = 12 + nt * 16
    directory = bytearray()
    body = bytearray()
    head_file_offset = None

    for tag in tags:
        tbytes = out_tables[tag]
        csum = calc_checksum(tbytes)
        if tag == 'head':
            head_file_offset = offset
        directory.extend(struct.pack('>4sIII', tag.encode('ascii'), csum, offset, len(tbytes)))
        body.extend(tbytes)
        pad = (4 - (len(tbytes) % 4)) % 4
        if pad:
            body.extend(b'\x00' * pad)
        offset += len(tbytes) + pad

    full = bytearray(header + directory + body)
    whole_csum = calc_checksum(full)
    adj = (0xB1B0AFBA - whole_csum) & 0xFFFFFFFF
    struct.pack_into('>I', full, head_file_offset + 8, adj)

    with open(dst_path, 'wb') as f:
        f.write(full)

    print(
        f"[OK] {dst_path}: {len(full)} bytes | glyphs: {num_glyphs} -> {final_num_glyphs} | "
        f"cmap: {len(cmap_map)} chars | bbox=({font_xmin},{font_ymin},{font_xmax},{font_ymax}) | "
        f"winAsc={new_win_asc} winDesc={new_win_desc}"
    )


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    fonts_dir = os.path.join(root, 'assets', 'fonts')
    build_extended_font(
        src_path=os.path.join(fonts_dir, 'OMORI_GAME2.ttf'),
        dst_path=os.path.join(fonts_dir, 'OMORI_GAME2_PTBR.ttf'),
        family_name='OMORI_GAME2_PTBR',
        ps_name='OMORI_GAME2_PTBR',
        is_title_font=False,
    )
    build_extended_font(
        src_path=os.path.join(fonts_dir, 'OMORI_GAME.ttf'),
        dst_path=os.path.join(fonts_dir, 'OMORI_GAME_PTBR.ttf'),
        family_name='OMORI_GAME_PTBR',
        ps_name='OMORI_GAME_PTBR',
        is_title_font=True,
    )


if __name__ == '__main__':
    main()

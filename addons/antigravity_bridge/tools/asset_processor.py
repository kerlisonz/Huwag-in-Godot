#!/usr/bin/env python3
"""
Asset Processor & Normalizer para o Antigravity Art Studio (Godot 4).
Processa, normaliza resoluções de pixel art (640x360, 512x512, 48x48)
e gera templates de cena compatíveis com o Huwag.
"""

import sys
import os
import argparse
import json
from PIL import Image

def normalize_image(input_path: str, output_path: str, target_w: int, target_h: int, use_nearest: bool = True) -> bool:
    try:
        if not os.path.isfile(input_path):
            print(f"ERRO: Arquivo de entrada não encontrado: {input_path}", file=sys.stderr)
            return False

        os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
        img = Image.open(input_path)

        # Converte para RGBA se necessário
        if img.mode not in ("RGB", "RGBA"):
            img = img.convert("RGBA")

        src_w, src_h = img.size
        target_aspect = target_w / target_h
        src_aspect = src_w / src_h

        # Ajuste de proporção (Center crop para não esticar a imagem)
        if abs(src_aspect - target_aspect) > 0.01:
            if src_aspect > target_aspect:
                # Imagem de origem mais larga: corta laterais
                new_w = int(src_h * target_aspect)
                left = (src_w - new_w) // 2
                img = img.crop((left, 0, left + new_w, src_h))
            else:
                # Imagem de origem mais alta: corta topo/baixo
                new_h = int(src_w / target_aspect)
                top = (src_h - new_h) // 2
                img = img.crop((0, top, src_w, top + new_h))

        # Redimensionamento
        resample_mode = Image.Resampling.NEAREST if use_nearest else Image.Resampling.LANCZOS
        resized = img.resize((target_w, target_h), resample=resample_mode)
        resized.save(output_path, "PNG", optimize=True)

        print(f"[OK] Imagem normalizada salva em: {output_path} ({target_w}x{target_h} px)")
        return True
    except Exception as e:
        print(f"ERRO ao normalizar imagem: {e}", file=sys.stderr)
        return False

def create_scene_template(scene_path: str, bg_texture_path: str, scene_title: str) -> bool:
    try:
        os.makedirs(os.path.dirname(os.path.abspath(scene_path)), exist_ok=True)
        
        # Converte caminhos locais para res:// se necessário
        res_bg = bg_texture_path.replace("\\", "/")
        if "res://" not in res_bg:
            # Encontra parte relativa ao projeto
            idx = res_bg.find("assets/")
            if idx != -1:
                res_bg = "res://" + res_bg[idx:]

        tscn_content = f"""[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://scenes/characters/Player.tscn" id="1_player"]
[ext_resource type="Texture2D" path="{res_bg}" id="2_bg"]

[node name="{scene_title}" type="Node2D"]

[node name="Background" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("2_bg")
centered = false

[node name="RoomWalls" type="StaticBody2D" parent="."]
collision_layer = 1

[node name="Wall_North" type="CollisionPolygon2D" parent="RoomWalls"]
polygon = PackedVector2Array(0, 0, 640, 0, 640, 156, 0, 156)

[node name="Wall_South" type="CollisionPolygon2D" parent="RoomWalls"]
polygon = PackedVector2Array(0, 325, 640, 325, 640, 360, 0, 360)

[node name="Wall_West" type="CollisionPolygon2D" parent="RoomWalls"]
polygon = PackedVector2Array(0, 0, 100, 0, 100, 360, 0, 360)

[node name="Interactables" type="Node2D" parent="."]

[node name="YSortEntities" type="Node2D" parent="."]
y_sort_enabled = true

[node name="Player" parent="YSortEntities" instance=ExtResource("1_player")]
position = Vector2(320, 240)
y_sort_enabled = true
"""
        with open(scene_path, "w", encoding="utf-8") as f:
            f.write(tscn_content)

        print(f"[OK] Cena .tscn criada com sucesso em: {scene_path}")
        return True
    except Exception as e:
        print(f"ERRO ao criar cena: {e}", file=sys.stderr)
        return False

def register_request(req_data: dict, req_path: str) -> bool:
    try:
        os.makedirs(os.path.dirname(os.path.abspath(req_path)), exist_ok=True)
        with open(req_path, "w", encoding="utf-8") as f:
            json.dump(req_data, f, indent=2, ensure_ascii=False)
        print(f"[OK] Solicitação registrada em: {req_path}")
        return True
    except Exception as e:
        print(f"ERRO ao salvar solicitação: {e}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description="Antigravity Asset Processor")
    subparsers = parser.add_subparsers(dest="command")

    norm_parser = subparsers.add_parser("normalize")
    norm_parser.add_argument("--input", required=True, help="Imagem de entrada")
    norm_parser.add_argument("--output", required=True, help="Imagem de saída")
    norm_parser.add_argument("--width", type=int, default=640, help="Largura alvo")
    norm_parser.add_argument("--height", type=int, default=360, help="Altura alvo")
    norm_parser.add_argument("--nearest", action="store_true", default=True, help="Usar amostragem Nearest Neighbor")

    scene_parser = subparsers.add_parser("create_scene")
    scene_parser.add_argument("--output", required=True, help="Caminho do arquivo .tscn")
    scene_parser.add_argument("--bg", required=True, help="Caminho da textura de fundo")
    scene_parser.add_argument("--title", default="NewScene", help="Nome do nó raiz")

    req_parser = subparsers.add_parser("request")
    req_parser.add_argument("--output", required=True, help="Caminho do JSON da solicitação")
    req_parser.add_argument("--slug", default="", help="Slug do asset")
    req_parser.add_argument("--mode", type=int, default=0, help="Modo do asset (0=room, 1=portrait, 2=item)")
    req_parser.add_argument("--preset", type=int, default=0, help="Preset de ambientação")
    req_parser.add_argument("--width", type=int, default=640, help="Largura alvo")
    req_parser.add_argument("--height", type=int, default=360, help="Altura alvo")
    req_parser.add_argument("--prompt", default="", help="Prompt do usuário")
    req_parser.add_argument("--full_prompt", default="", help="Prompt completo")
    req_parser.add_argument("--target_file", default="", help="Caminho do arquivo final")

    args = parser.parse_args()

    if args.command == "normalize":
        success = normalize_image(args.input, args.output, args.width, args.height, args.nearest)
        sys.exit(0 if success else 1)
    elif args.command == "create_scene":
        success = create_scene_template(args.output, args.bg, args.title)
        sys.exit(0 if success else 1)
    elif args.command == "request":
        data = {
            "slug": args.slug,
            "mode": args.mode,
            "preset": args.preset,
            "resolution": [args.width, args.height],
            "user_prompt": args.prompt,
            "full_prompt": args.full_prompt,
            "target_file": args.target_file,
            "reference_bg": "res://assets/levels/room_huwag/room_huwag_bg.png"
        }
        success = register_request(data, args.output)
        sys.exit(0 if success else 1)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()

"""Render mocked native frame geometry for layout inspection, not an in-game screenshot."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile

from test_journal import ROOT, lua_executable, run_lua

# Optional local development dependency, kept outside the addon package.
sys.path.append(str(Path(os.environ.get("TEMP", "/tmp")) / "fw-journal-preview"))
from PIL import Image, ImageDraw, ImageFont


def rgba(value, default=(0.24, 0.16, 0.08, 1)):
    value = value or default
    return tuple(round(min(1, max(0, x)) * 255) for x in (*value[:3], value[3] if len(value) > 3 else 1))


def font_metrics(path):
    # Measure the substitute preview fonts so the mock lays out the same glyphs.
    # These measurements are not claims about the native WoW fonts.
    font_root=Path(os.environ.get("WINDIR", "C:/Windows"))/"Fonts"
    glyphs="".join(chr(i) for i in range(32,127))+"·›‹∞◆–—•"
    tables=[]
    for role,face in (("bold","georgiab.ttf"),("regular","georgia.ttf")):
        font=ImageFont.truetype(str(font_root/face),100)
        values=",".join(f"[{json.dumps(g,ensure_ascii=False)}]={font.getlength(g)/100:.5f}" for g in glyphs)
        tables.append(f"{role}={{{values}}}")
    path.write_text("return {"+",".join(tables)+"}",encoding="utf-8")


def render(nodes, output):
    bounds = nodes[0]["clip"]
    canvas = Image.new("RGBA", (round(bounds["w"]), round(bounds["h"])), (22, 15, 8, 255))
    for node in sorted(nodes, key=lambda n: (n["level"], n["layer"], n["order"])):
        r = node["rect"]
        x, y, w, h = r["x"], r["y"], r["w"], r["h"]
        if w <= 0 or h <= 0:
            continue
        layer = Image.new("RGBA", canvas.size)
        draw = ImageDraw.Draw(layer)
        kind, template = node["kind"], node.get("template") or ""
        if node.get("backdrop"):
            draw.rectangle((x, y, x + w, y + h), fill=rgba(node["backdrop"]), outline=rgba(node.get("border")), width=1)
        if kind == "Texture":
            texture = str(node.get("texture") or "")
            if texture.endswith("JournalBook"):
                artwork = Image.open(ROOT / "art/ForeverWayfinder-journal-book-source.png").convert("RGBA").resize((round(w), round(h)))
                layer.paste(artwork, (round(x), round(y)))
            elif texture.endswith("Media\\Icon"):
                icon = Image.open(ROOT / "art/ForeverWayfinder-compass-source.png").convert("RGBA").resize((round(w), round(h)))
                if node.get("masked"):
                    mask=Image.new("L",icon.size)
                    ImageDraw.Draw(mask).ellipse((0,0,icon.width-1,icon.height-1),fill=255)
                    icon.putalpha(mask)
                layer.paste(icon, (round(x), round(y)), icon)
            elif texture:
                draw.rectangle((x, y, x + w, y + h), fill=(76, 57, 29, 255), outline=(163, 131, 69, 255), width=2)
                draw.line((x+6,y+6,x+w-6,y+h-6),fill=(207,178,110,255),width=2)
            elif node.get("color"):
                draw.rectangle((x, y, x+w, y+h), fill=rgba(node["color"]))
        if kind == "CheckButton":
            draw.rectangle((x+2,y+2,x+w-2,y+h-2),fill=(58,43,23,255),outline=(146,115,54,255),width=2)
            if node.get("checked"):
                draw.line([(x+5,y+10),(x+9,y+15),(x+18,y+5)],fill=(238,203,78,255),width=3)
        is_native_button = kind == "Button" and template == "UIPanelButtonTemplate"
        if is_native_button:
            draw.rectangle((x,y,x+w,y+h),fill=(99,13,8,255),outline=(109,89,50,255),width=2)
            draw.line((x+3,y+3,x+w-3,y+3),fill=(184,63,25,255),width=1)
        if kind == "ScrollFrame" and template == "UIPanelScrollFrameTemplate":
            draw.rectangle((x+w+3,y,x+w+15,y+h),fill=(82,59,31,120))
            draw.rectangle((x+w+4,y+17,x+w+14,y+43),fill=(147,121,68,220),outline=(65,46,26,255))
            draw.polygon([(x+w+3,y+10),(x+w+15,y+10),(x+w+9,y+3)],fill=(151,117,52,255))
            draw.polygon([(x+w+3,y+h-10),(x+w+15,y+h-10),(x+w+9,y+h-3)],fill=(151,117,52,255))
        value = node.get("text") or ""
        if value and (kind in ("FontString", "EditBox") or is_native_button):
            value = re.sub(r"\|T.*?\|t", "◆ ", value)
            value = re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", value)
            size = node.get("fontSize") or (20 if node.get("font") in ("QuestFont_Large", "GameFontNormalLarge") else 12)
            face = "georgiab.ttf" if node.get("font") in ("QuestFont_Large", "GameFontNormalLarge", "GameFontNormal") else "georgia.ttf"
            font = ImageFont.truetype(str(Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / face), round(size))
            fill = rgba(node.get("color"))
            if is_native_button:
                fill = (250,205,70,255) if node.get("enabled") is not False else (158,143,113,255)
            lines = []
            for paragraph in value.splitlines():
                line = ""
                for word in paragraph.split(" "):
                    candidate = (line + " " + word).strip()
                    if node.get("wrap") is not False and draw.textlength(candidate,font=font)>w and line:
                        lines.append(line); line=word
                    else:
                        line=candidate
                lines.append(line)
            line_height = size * 1.18 + (node.get("spacing") or 0)
            for i,line in enumerate(lines):
                if i*line_height + size*1.18 > h+2:
                    break
                tx = x
                if is_native_button or node.get("justify") == "CENTER": tx += (w-draw.textlength(line,font=font))/2
                elif node.get("justify") == "RIGHT": tx += w-draw.textlength(line,font=font)
                ty=y+i*line_height + ((h-line_height)/2 if is_native_button else -2)
                draw.text((round(tx),round(ty)),line,font=font,fill=fill)
        clip = node["clip"]
        box = (round(max(0,clip["x"])),round(max(0,clip["y"])),round(min(canvas.width,clip["x"]+clip["w"])),round(min(canvas.height,clip["y"]+clip["h"])))
        if box[2]>box[0] and box[3]>box[1]:
            cut=layer.crop(box); canvas.alpha_composite(cut,(box[0],box[1]))
    output.parent.mkdir(parents=True,exist_ok=True)
    canvas.convert("RGB").save(output)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua")
    parser.add_argument("--state",choices=("quest","note","empty","chain","where","book"),default="quest")
    parser.add_argument("--text-size",choices=("standard","large","extra"),default="standard")
    parser.add_argument("--output",type=Path,default=ROOT/"dist/journal-layout-preview.png")
    args=parser.parse_args()
    script="reading_test.lua" if args.state in ("chain","where","book") else "journal_ui_test.lua"
    with tempfile.TemporaryDirectory(prefix="fw-reading-preview-") as folder:
        metrics=Path(folder)/"font-metrics.lua"
        font_metrics(metrics)
        result=run_lua(lua_executable(args.lua),ROOT/"tests"/script,"preview",args.state,args.text_size,metrics.as_posix())
    if result.returncode or result.stderr:
        raise SystemExit(result.stdout+result.stderr)
    nodes=json.loads(result.stdout)
    render(nodes,args.output)
    print(f"Layout preview (mocked native UI): {args.output}")


if __name__=="__main__":
    main()

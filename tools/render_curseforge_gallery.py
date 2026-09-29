"""Create labeled gallery previews from the shipped addon UI and example data.

These images are not captured in WoW. The mock supplies layout and example
records; the preview renderer substitutes fonts and native control textures.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED

from render_journal_preview import Image, ImageDraw, ImageFont, font_metrics, render
from test_journal import ROOT, lua_executable, run_lua

SIZE = (1600, 1200)
GOLD = (241, 204, 121)
CREAM = (238, 221, 185)
MUTED = (187, 161, 121)
BG = (24, 17, 11)
FONT_ROOT = Path("C:/Windows/Fonts")
VERSION = re.search(r"^## Version:\s*(\S+)", (ROOT/"ForeverWayfinder/ForeverWayfinder.toc").read_text(encoding="utf-8"), re.MULTILINE).group(1)
PAGES = (
    ("01-discovery-journal.png", "Discovery Journal", "Quests, places, dungeon visits, and level milestones, saved as you play."),
    ("02-search-and-filters.png", "Search and filters", "Search your discoveries and notes. Narrow the results by zone, type, class, and character."),
    ("03-personal-notes.png", "Personal notes", "Keep your own notes and tags. Favorite discoveries and mark places to revisit."),
    ("04-classic-quest-chains.png", "Classic quest chains", "Browse connected Classic quests, then expand a step for details and map links."),
    ("05-where-next.png", "Where next?", "Find possible Classic quest starts that match your character and quest progress."),
    ("06-quest-markers-and-minimap.png", "Quest markers and minimap access", "Spot quest types in your log and open the journal from the minimap compass."),
    ("07-reading-options.png", "Choose your text size", "Standard, Large, and Extra Large. Your choice is saved across Wayfinder screens."),
)


def font(size, bold=False):
    return ImageFont.truetype(str(FONT_ROOT / ("georgiab.ttf" if bold else "georgia.ttf")), size)


def text(canvas, xy, value, size=24, color=CREAM, width=None, bold=False, spacing=10):
    draw = ImageDraw.Draw(canvas)
    face = font(size, bold)
    x, y = xy
    for paragraph in value.split("\n"):
        line = ""
        lines = []
        for word in paragraph.split(" "):
            candidate = (line + " " + word).strip()
            if width and line and draw.textlength(candidate, font=face) > width:
                lines.append(line)
                line = word
            else:
                line = candidate
        lines.append(line)
        for line in lines:
            draw.text((x, y), line, font=face, fill=color)
            y += size * 1.3 + spacing
    return y


def page(index):
    _, title, subtitle = PAGES[index]
    canvas = Image.new("RGB", SIZE, BG)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((24, 24, 1575, 1175), outline=(103, 76, 36), width=2)
    text(canvas, (56, 42), title, 42, GOLD, bold=True)
    text(canvas, (57, 105), subtitle, 21, CREAM, width=1320)
    draw.line((56, 147, 1544, 147), fill=(115, 84, 37), width=1)
    draw.line((56, 1148, 1544, 1148), fill=(115, 84, 37), width=1)
    text(canvas, (57, 1156), "UI preview · Example data · Native fonts and controls approximated", 16, MUTED)
    label = f"Forever Wayfinder {VERSION}"
    face = font(16)
    draw.text((1543-draw.textlength(label,font=face),1156),label,font=face,fill=GOLD)
    return canvas


def paste(canvas, source, xy, scale=1):
    source = source.convert("RGB")
    if scale != 1:
        source = source.resize((round(source.width*scale),round(source.height*scale)),Image.Resampling.LANCZOS)
    canvas.paste(source, xy)
    return source.size


def callout(canvas, xy, title, body, width=470):
    y = text(canvas, xy, title, 30, GOLD, width=width, bold=True, spacing=5)
    return text(canvas,(xy[0],y+8),body,25,CREAM,width=width,spacing=10)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,default=ROOT/"dist/curseforge-gallery")
    parser.add_argument("--lua")
    args = parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    executable = lua_executable(args.lua)
    with tempfile.TemporaryDirectory(prefix="fw-gallery-") as temporary:
        folder = Path(temporary)
        metrics = folder/"font-metrics.lua"
        font_metrics(metrics)
        def scene(name,preset="large"):
            result=run_lua(executable,ROOT/"tests/gallery_preview.lua",name,preset,metrics.as_posix())
            if result.returncode or result.stderr:
                raise SystemExit(result.stdout+result.stderr)
            nodes=json.loads(result.stdout)
            path=folder/f"{name}-{preset}.png"
            render(nodes,path)
            return Image.open(path).copy()

        for index,state in enumerate(("journal","search","notes")):
            canvas=page(index)
            paste(canvas,scene(state),(176,169),1.2)
            canvas.save(args.output/PAGES[index][0])

        canvas=page(3)
        text(canvas,(170,178),"The chain",27,GOLD,bold=True)
        text(canvas,(837,178),"An expanded step",27,GOLD,bold=True)
        paste(canvas,scene("chain-overview","standard"),(170,232),1.35)
        paste(canvas,scene("chain-details","standard"),(837,232),1.35)
        text(canvas,(172,1061),"Classic reference: Forever may change the steps, locations, requirements, and rewards.",21,MUTED,width=1240)
        canvas.save(args.output/PAGES[3][0])

        canvas=page(4)
        paste(canvas,scene("where","standard"),(164,204),1.5)
        callout(canvas,(927,285),"Suggested areas","See a few nearby or suitable zones for your level.",width=495)
        callout(canvas,(927,524),"Possible quest starts","Suggestions account for your level, faction, race, class, and known quest progress.",width=495)
        callout(canvas,(927,809),"Starter waypoints","Click a quest to set a waypoint to its Classic starter. Forever may change the location.",width=495)
        canvas.save(args.output/PAGES[4][0])

        canvas=page(5)
        paste(canvas,scene("badges","standard"),(88,237),1.45)
        callout(canvas,(945,238),"∞  Possible Forever quest","The quest ID is missing from the Classic reference. Its later steps stay a surprise.",width=545)
        callout(canvas,(945,483),"D  Dungeon quest","The client marks the quest as a dungeon quest.",width=545)
        # Place the exported compass button in a clearly identified schematic.
        mini=scene("minimap")
        diagram=Image.new("RGB",mini.size,BG)
        d=ImageDraw.Draw(diagram)
        d.ellipse((60,36,200,176),fill=(55,62,38),outline=(148,117,60),width=4)
        d.line((130,48,130,164),fill=(88,88,55),width=1)
        d.line((72,106,188,106),fill=(88,88,55),width=1)
        d.text((124,42),"N",font=font(14),fill=GOLD)
        # The fixture exports only the addon button; its plain canvas is masked.
        pixels=mini.load(); mask=Image.new("L",mini.size,0); mp=mask.load()
        for y in range(mini.height):
            for x in range(mini.width):
                if pixels[x,y] != (22,15,8): mp[x,y]=255
        diagram.paste(mini,(0,0),mask)
        paste(canvas,diagram,(116,867),1)
        callout(canvas,(388,871),"Minimap compass","Click to open or close your journal. Drag the button around the minimap; its position is saved.",width=1050)
        text(canvas,(143,1090),"Minimap schematic",16,MUTED)
        canvas.save(args.output/PAGES[5][0])

        canvas=page(6)
        for x,preset,label in ((88,"standard","Standard"),(595,"large","Large"),(1102,"extra","Extra Large")):
            text(canvas,(x,212),label,30,GOLD,bold=True)
            paste(canvas,scene("reading",preset),(x,275),.94)
        callout(canvas,(104,901),"One saved reading setting","Use the Text button in the Journal, Chain, or Where next? panel. Fold personal notes when you want more room for a quest's story.",width=1370)
        text(canvas,(104,1056),"/fw text standard       /fw text large       /fw text extra",23,GOLD)
        canvas.save(args.output/PAGES[6][0])

    captions=["# Forever Wayfinder gallery\n","These are labeled UI previews rendered from the addon code with example records. They are not in-game screenshots; native fonts and textures are approximated. The minimap and quest-log background in image 06 are schematic.\n"]
    for name,title,caption in PAGES:
        captions.append(f"## {title}\n\nFile: `{name}`\n\n{caption}\n")
    (args.output/"CAPTIONS.md").write_text("\n".join(captions),encoding="utf-8")
    sheet=Image.new("RGB",(1200,1320),BG)
    for index,(name,title,_) in enumerate(PAGES):
        x,y=(index%2)*600,(index//2)*330
        thumbnail=Image.open(args.output/name).resize((400,300),Image.Resampling.LANCZOS)
        sheet.paste(thumbnail,(x+10,y+10))
        text(sheet,(x+425,y+28),f"{index+1:02d}",24,GOLD,bold=True)
        text(sheet,(x+425,y+78),title,18,CREAM,width=150,spacing=5)
    sheet.save(args.output/"CONTACT-SHEET.png")
    archive=args.output.parent/"ForeverWayfinder-CurseForge-gallery.zip"
    with ZipFile(archive,"w",ZIP_DEFLATED,compresslevel=9) as z:
        for name,_,_ in PAGES: z.write(args.output/name,name)
        z.write(args.output/"CAPTIONS.md","CAPTIONS.md")
        z.write(args.output/"CONTACT-SHEET.png","CONTACT-SHEET.png")
    with ZipFile(archive) as z:
        assert z.testzip() is None
    print(f"Created {len(PAGES)} labeled 1600×1200 PNG previews: {args.output}")
    print(f"Gallery zip: {archive} ({archive.stat().st_size:,} bytes)")


if __name__=="__main__":
    main()

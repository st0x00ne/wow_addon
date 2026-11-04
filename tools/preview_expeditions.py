"""Build a local gallery from the add-on's real Lua frame geometry at three text sizes."""
from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
import tempfile
import webbrowser

from render_journal_preview import ROOT, font_metrics, lua_executable, render, run_lua

STATES = {
    "expeditions": "Hall of Thanes map",
    "expeditions-fullmap": "Hall of Thanes enlarged",
    "expeditions-lordaeron": "Ruins of Lordaeron map",
    "expeditions-dalaran": "Dalaran, second map",
    "expeditions-route": "Quest circuit",
    "expeditions-loot": "Loot and wishlist",
    "expeditions-quests": "Dungeon quests",
    "expeditions-raid": "Announced raid",
    "expeditions-empty": "Empty search",
}
SIZES = ("standard", "large", "extra")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua")
    parser.add_argument("--open", action="store_true", help="Open the completed gallery in your default browser.")
    parser.add_argument("--output", type=Path, default=ROOT / "dist/expeditions-preview")
    args = parser.parse_args()
    executable = lua_executable(args.lua)
    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="fw-expedition-preview-") as folder:
        metrics = Path(folder) / "metrics.lua"
        font_metrics(metrics)
        checked = run_lua(executable, ROOT / "tests/expeditions_test.lua", "layout", metrics.as_posix())
        if checked.returncode or checked.stderr or "PASS:" not in checked.stdout:
            raise SystemExit(checked.stdout + checked.stderr)
        print(checked.stdout.strip(), flush=True)
        for state in STATES:
            for size in SIZES:
                result = run_lua(executable, ROOT / "tests/expeditions_test.lua",
                                 "preview", state, size, metrics.as_posix())
                if result.returncode or result.stderr:
                    raise SystemExit(result.stdout + result.stderr)
                nodes = json.loads(result.stdout)
                output = args.output / f"{state}-{size}.png"
                render(nodes, output)
                print(output.name, flush=True)
    options = "".join(f'<option value="{state}">{html.escape(label)}</option>' for state, label in STATES.items())
    document = '''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wayfinder — Expeditions preview</title>
<style>
:root { --paper:#181d1d; --ink:#eee3cb; --muted:#c4bdac; --gold:#e8ba63; --edge:#786345; --font:Georgia,serif; }
* { box-sizing:border-box; } html,body { overflow-x:clip; }
body { margin:0; background:var(--paper); color:var(--ink); font-family:var(--font); }
header,footer { max-width:1280px; margin:24px auto; padding:0 20px; }
h1 { font-size:28px; margin:0 0 12px; } p { line-height:1.6; max-width:88ch; color:var(--muted); }
nav { display:flex; flex-wrap:wrap; gap:16px; align-items:center; }
label { display:flex; gap:8px; align-items:center; } select { font:inherit; padding:8px; background:var(--paper); color:var(--ink); border:1px solid var(--edge); }
select:focus-visible,a:focus-visible { outline:2px solid var(--gold); outline-offset:3px; }
a { color:var(--gold); } figure { margin:0 auto; max-width:1280px; } img { display:block; width:100%; height:auto; }
code { overflow-wrap:anywhere; } figcaption { padding:8px 20px; color:var(--muted); }
</style>
<header><h1>Wayfinder / Expeditions</h1>
<p>These captures run the add-on's Lua against mocked WoW frames, then draw the exported layout with substitute fonts.
Use them to review spacing, reading sizes, and content states. Native game rendering and behavior still need a client check.</p>
<nav aria-label="Preview controls"><label>View <select id="view">OPTIONS</select></label>
<label>Text <select id="size"><option value="standard">Standard</option><option value="large">Large</option><option value="extra">Extra Large</option></select></label>
<a id="full" href="expeditions-standard.png">Open full resolution</a></nav></header>
<figure><img id="screen" src="expeditions-standard.png" alt="Wayfinder Hall of Thanes map at Standard text size">
<figcaption id="caption">Hall of Thanes · Standard. Original Atlas map; beta reference.</figcaption></figure>
<footer><p>The controls select captured states; the picture itself is static. In-game interactions are exercised by the Lua tests.</p>
<p>Maps by the <a href="https://github.com/arithmandar/Atlas-Kalimdor-and-Eastern-Kingdoms">Atlas Team</a>, included unchanged with their notices. Live layouts and boss positions still need checking.</p>
<p>Rebuild and open: <code>python tools/preview_expeditions.py --open</code><br>Test: <code>python tools/test_journal.py</code></p></footer>
<script>
const view=document.getElementById('view'),size=document.getElementById('size'),screen=document.getElementById('screen');
function update(){const name=view.selectedOptions[0].text+' · '+size.selectedOptions[0].text;
screen.src=view.value+'-'+size.value+'.png';screen.alt='Wayfinder '+name;
document.getElementById('full').href=screen.src;
document.getElementById('caption').textContent=name+(view.value==='expeditions-route'?'. Encounter itinerary; schematic only.':'. Atlas maps and encounter data are reference information, pending live verification.');}
view.addEventListener('change',update);size.addEventListener('change',update);
</script></html>'''.replace("OPTIONS", options)
    (args.output / "index.html").write_text(document, encoding="utf-8")
    print(f"Gallery: {args.output / 'index.html'}")
    if args.open:
        webbrowser.open((args.output / "index.html").resolve().as_uri())


if __name__ == "__main__":
    main()

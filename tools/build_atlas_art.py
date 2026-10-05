"""Export original Atlas paintings as game textures and preview crops."""
from pathlib import Path
import os
import sys

sys.path.append(str(Path(os.environ.get("TEMP", "/tmp")) / "fw-journal-preview"))
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "ForeverWayfinder/Media"
SHEETS = {
    "AtlasKalimdor-source.png": [1438, 1411, 1412, 2521, 1413, 1439, 1442, 1440,
        1441, 1443, 1445, 1444, 1446, 1447, 1448, 1449, 1452, 1451, None, None],
    "AtlasEastern-source.png": [1429, 1426, 1420, 1436, 1432, 1421, 1433, 1431,
        1437, 1424, 1434, 1417, 1418, 2548, 1425, 1427, 1428, 1419, 1422, 1423],
}

def main():
    destination = MEDIA / "Zones"
    destination.mkdir(parents=True, exist_ok=True)
    count = 0
    for name, maps in SHEETS.items():
        source = Image.open(ROOT / "art" / name).convert("RGB")
        for index, map_id in enumerate(maps):
            if map_id is None:
                continue
            col, row = index % 4, index // 4
            # A small inset prevents a neighboring scene from bleeding at edges.
            box = (round(col * source.width / 4) + 2, round(row * source.height / 5) + 2,
                round((col + 1) * source.width / 4) - 2, round((row + 1) * source.height / 5) - 2)
            source.crop(box).resize((512, 256), Image.Resampling.LANCZOS).save(destination / f"{map_id}.tga")
            count += 1
    frame = Image.open(ROOT / "art/AtlasFrameV2-source.png").convert("RGB")
    frame.resize((2048, 1024), Image.Resampling.LANCZOS).save(MEDIA / "AtlasFrameV2.tga")
    print(f"Exported {count} zone paintings and the Atlas frame")

if __name__ == "__main__":
    main()

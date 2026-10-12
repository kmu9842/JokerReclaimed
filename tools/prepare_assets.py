"""Convert the private Sunburst original to Balatro's 1x/2x atlas formats."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / 'art/source/forge-gpt-image-2-5-sunburst-1.png'
with Image.open(source) as image:
    image.verify()
with Image.open(source) as image:
    small = image.convert('RGB').resize((32, 32), Image.Resampling.NEAREST)
    colours = ['374244', '1D292C', 'F1E9D2', 'BFC7D5', 'FE5F55', '4BC292', 'EAC058']
    palette = Image.new('P', (1, 1))
    rgb = [int(c[i:i+2], 16) for c in colours for i in (0, 2, 4)]
    palette.putpalette(rgb + rgb[:3] * (256 - len(colours)))
    small = small.quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
    for scale in (1, 2):
        target = root / f'JokerReclaimed/assets/{scale}x'
        target.mkdir(parents=True, exist_ok=True)
        atlas = small.resize((32 * scale, 32 * scale), Image.Resampling.NEAREST)
        atlas.save(target / 'scraps.png')
        atlas.save(target / 'modicon.png')
print('Validated Sunburst PNG; exported four 32/64-pixel palette-matched atlases.')

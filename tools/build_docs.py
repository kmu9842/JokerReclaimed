"""Validate localized copy and compose guides from real, unmodified game captures."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import zipfile

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
LANGUAGES = json.loads((DOCS / 'listing-text.json').read_text(encoding='utf-8'))
parser = argparse.ArgumentParser()
parser.add_argument('--text-only', action='store_true')
parser.add_argument('--capture-dir', type=Path,
                    default=Path(os.environ['APPDATA']) / 'Balatro-JRC-QA')
parser.add_argument('--game-dir', type=Path,
                    default=Path(r'E:\SteamLibrary\steamapps\common\Balatro'))
args = parser.parse_args()
expected = {p.stem for p in (ROOT / 'JokerReclaimed/localization').glob('*.lua')}
assert set(LANGUAGES) == expected and len(expected) == 15
for key, entry in LANGUAGES.items():
    assert 0 < len(entry['intro']) <= 100, (key, 'intro', len(entry['intro']))
    assert 0 < len(entry['usage']) <= 200, (key, 'usage', len(entry['usage']))
    assert len(entry['steps']) == 4

index = ['# Joker Reclaimed — 15 languages', '',
         '각 소개는 100자 이내, 사용법은 200자 이내입니다. 공백과 문장부호를 포함한 Unicode 문자 수입니다.', '',
         'Each introduction is at most 100 characters; each usage text is at most 200, including spaces and punctuation.', '',
         'Install Lovely and Steamodded, then extract the release ZIP into the Balatro Mods directory. '
         'Open the shop to use F7. See the [full instructions](../JokerReclaimed/README.md).', '',
         '| Language | Introduction | Usage | Screenshots and guide |',
         '|---|---:|---:|---|']
offline = ['# Joker Reclaimed — Languages', '',
           'Introduction: ≤100 characters. Usage: ≤200 characters. Spaces and punctuation count.', '',
           '[Actual screenshots and illustrated guides](https://github.com/kmu9842/JokerReclaimed/blob/main/docs/LANGUAGES.md)', '']
(DOCS / 'languages').mkdir(exist_ok=True)
for key, entry in LANGUAGES.items():
    index.append(f'| {entry["language"]} | {len(entry["intro"])} | {len(entry["usage"])} | [Open](languages/{key}.md) |')
for key, entry in LANGUAGES.items():
    section = [f'## {entry["language"]} (`{key}`)', '', entry['intro'], '', entry['usage'], '']
    index.extend(section + [f'[Screenshot](images/screenshots/{key}-intro.png) · [Guide](images/guides/{key}.png)', ''])
    offline.extend(section)
    page = [f'# {entry["guide_title"]}', '', entry['intro'], '', entry['usage'], '',
            f'![{entry["language"]}](../images/screenshots/{key}-intro.png)', '']
    page.extend(f'{i}. {text}' for i, text in enumerate(entry['steps'], 1))
    page.extend(['', entry['note'], '', f'![{entry["guide_title"]}](../images/guides/{key}.png)', '',
                 f'[1](../images/screenshots/{key}-shop.png) · [2](../images/screenshots/{key}-tear.png) · '
                 f'[3](../images/screenshots/{key}-intro.png) · [4](../images/screenshots/{key}-options.png) · '
                 f'[✂](../images/screenshots/{key}-effect.png)', ''])
    (DOCS / f'languages/{key}.md').write_text('\n'.join(page), encoding='utf-8')
(DOCS / 'LANGUAGES.md').write_text('\n'.join(index), encoding='utf-8')
(ROOT / 'JokerReclaimed/LANGUAGES.md').write_text('\n'.join(offline), encoding='utf-8')
print('PASS: 15 introductions <=100 characters and 15 usage texts <=200 characters')
if args.text_only:
    raise SystemExit(0)

report = json.loads((args.capture_dir / 'capture-report.json').read_text(encoding='utf-8'))
assert report.get('success') and report['identity'] == 'Balatro-JRC-QA'
assert set(report['languages']) == expected and len(report['files']) == 75
screens = DOCS / 'images/screenshots'
guides = DOCS / 'images/guides'
screens.mkdir(parents=True, exist_ok=True)
guides.mkdir(parents=True, exist_ok=True)
fonts = ROOT / '.local/guide-fonts'
fonts.mkdir(parents=True, exist_ok=True)
font_names = {'ko': 'NotoSansKR-Bold.ttf', 'ja': 'NotoSansJP-Bold.ttf',
              'zh_CN': 'NotoSansSC-Bold.ttf', 'zh_TW': 'NotoSansTC-Bold.ttf'}
# Fonts are used locally for rendering captions, never included in the release.
with zipfile.ZipFile(args.game_dir / 'Balatro.exe') as game:
    for name in set(font_names.values()) | {'NotoSans-Bold.ttf'}:
        (fonts / name).write_bytes(game.read('resources/fonts/' + name))

manifest = {'method': 'LOVE captureScreenshot: actual game frames; no generated or redrawn UI',
            'resolution': [1600, 900], 'crt': 0, 'bloom': 1, 'identity': report['identity'],
            'fixture': 'Isolated seeded shop with example funds, no user saves or Steam integration',
            'guide_method': 'Four entire screenshots resized uniformly, with captions outside the frames',
            'files': {}}
for filename in report['files']:
    src = args.capture_dir / filename
    dst = screens / src.name
    with Image.open(src) as img:
        assert img.size == (1600, 900)
        img.verify()
    shutil.copyfile(src, dst)
    manifest['files'][str(dst.relative_to(DOCS)).replace('\\', '/')] = hashlib.sha256(dst.read_bytes()).hexdigest()

BG, CARD, GOLD, WHITE, MUTED = '#1d2b2a', '#263c3a', '#efcc83', '#f4e9cd', '#aec8c0'
for key, entry in LANGUAGES.items():
    font_path = str(fonts / font_names.get(key, 'NotoSans-Bold.ttf'))
    title = ImageFont.truetype(font_path, 43)
    caption = ImageFont.truetype(font_path, 28)
    body = ImageFont.truetype(font_path, 24)
    label = ImageFont.truetype(str(fonts / 'NotoSans-Bold.ttf'), 23)
    canvas = Image.new('RGB', (1400, 3650), BG)
    draw = ImageDraw.Draw(canvas)

    def wrapped(text, font, width):
        # Word wrapping for alphabetic scripts; character wrapping for CJK.
        units = list(text) if key in font_names else text.split(' ')
        separator = '' if key in font_names else ' '
        lines, line = [], ''
        for unit in units:
            candidate = line + (separator if line else '') + unit
            if line and draw.textlength(candidate, font=font) > width:
                lines.append(line)
                line = unit
            else:
                line = candidate
        return lines + ([line] if line else [])

    draw.text((60, 30), 'JOKER RECLAIMED  /  1.0.0', font=label, fill=GOLD)
    draw.text((60, 70), entry['guide_title'], font=title, fill=WHITE)
    for i, line in enumerate(wrapped(entry['intro'], body, 1280)):
        draw.text((60, 137 + i * 35), line, font=body, fill=MUTED)

    for step, suffix in enumerate(('shop', 'tear', 'intro', 'options')):
        top = 235 + step * 830
        draw.rounded_rectangle((40, top, 1360, top + 810), radius=16, fill=CARD)
        draw.ellipse((60, top + 17, 112, top + 69), fill=GOLD)
        draw.text((86, top + 41), str(step + 1), font=caption, fill=BG, anchor='mm')
        lines = wrapped(entry['steps'][step], caption, 1210)
        assert len(lines) <= 2, (key, step, lines)
        for i, line in enumerate(lines):
            draw.text((130, top + 14 + i * 35), line, font=caption, fill=WHITE)
        with Image.open(screens / f'{key}-{suffix}.png') as frame:
            frame = frame.convert('RGB').resize((1280, 720), Image.Resampling.LANCZOS)
            canvas.paste(frame, (60, top + 80))
    for i, line in enumerate(wrapped(entry['note'], body, 1280)):
        draw.text((60, 3570 + i * 32), line, font=body, fill=GOLD)
    dst = guides / f'{key}.png'
    canvas.save(dst, optimize=True)
    manifest['files'][f'images/guides/{key}.png'] = hashlib.sha256(dst.read_bytes()).hexdigest()
    print(f'Guide: {key}')
(DOCS / 'capture-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('PASS: 75 original screenshots and 15 illustrated guides')

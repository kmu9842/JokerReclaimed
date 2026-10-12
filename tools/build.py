"""Create a standard single-folder mod ZIP and SHA-256 checksum."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--guides', action='store_true', help='Also package the captured multilingual guides')
args = parser.parse_args()
mod = root / 'JokerReclaimed'
metadata = json.loads((mod / 'JokerReclaimed.json').read_text(encoding='utf-8'))
out = root / 'dist'
out.mkdir(exist_ok=True)
archive = out / f'JokerReclaimed-{metadata["version"]}.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
    for path in sorted(mod.rglob('*')):
        if path.is_file():
            package.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n', encoding='ascii')
print(f'Built and verified: {archive} ({archive.stat().st_size:,} bytes)')

if args.guides:
    docs = root / 'docs'
    manifest = json.loads((docs / 'capture-manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['files']) == 90
    for relative, expected in manifest['files'].items():
        assert hashlib.sha256((docs / relative).read_bytes()).hexdigest() == expected, relative
    guide_archive = out / f'JokerReclaimed-{metadata["version"]}-guides.zip'
    with zipfile.ZipFile(guide_archive, 'w', zipfile.ZIP_DEFLATED) as package:
        for path in sorted(docs.rglob('*')):
            if path.is_file():
                package.write(path, path.relative_to(root).as_posix())
        for name in ('README.md', 'LANGUAGES.md', 'LICENSE'):
            package.write(mod / name, 'JokerReclaimed/' + name)
    with zipfile.ZipFile(guide_archive) as package:
        assert package.testzip() is None
    digest = hashlib.sha256(guide_archive.read_bytes()).hexdigest()
    guide_archive.with_suffix('.zip.sha256').write_text(f'{digest}  {guide_archive.name}\n', encoding='ascii')
    print(f'Built and verified: {guide_archive} ({guide_archive.stat().st_size:,} bytes)')

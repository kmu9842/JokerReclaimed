"""Create a standard single-folder mod ZIP and SHA-256 checksum."""
import hashlib
import json
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
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

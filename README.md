# Joker Reclaimed 개발 프로젝트

완성 모드 소스는 [JokerReclaimed](JokerReclaimed), 사용자 설명과 가격표는 [모드 설명서](JokerReclaimed/README.md)에 있습니다. 수치는 [balance.lua](JokerReclaimed/balance.lua)에서 수정합니다.

## 검증

Balatro에 포함된 LuaJIT DLL을 사용합니다. 설치 위치가 다르면 `--game-dir`을 지정하세요.

```powershell
python tools/run_lua.py --syntax
python tools/run_lua.py tests/unit.lua tests/localization.lua
```

실제 게임을 실행하거나 자동 조작하는 테스트는 사용자가 명시적으로 요청할 때만 실행합니다. 코드 수정 시에는 위 구문·단위 검사만 사용합니다.

실행 검증은 `.local/qa-mods`에 Steamodded, 설치된 DVPreview·QuickRestart와 테스트 모드를 복사해 실행합니다. 저장 identity를 `Balatro-JRC-QA`로 고정하고 Steam 연동을 끕니다. 매 실행 전 이 테스트 저장 폴더만 초기화하며 실제 Balatro 프로필과 조각 지갑은 수정하지 않습니다. 검증이 끝나면 게임이 자동으로 종료됩니다.

결과와 화면은 `%APPDATA%\Balatro-JRC-QA\qa-report.json`, `qa-*.png`로 저장됩니다. 테스트 모드는 배포 폴더에 포함되지 않습니다.

## 빌드와 설치

```powershell
python tools/build.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools/install.ps1
```

빌드는 `dist/JokerReclaimed-1.0.2.zip`과 SHA-256 체크섬을 만듭니다. 설치 스크립트는 기존 설치가 있으면 `.local/install-backups`에 백업하고 사용자 설정을 보존하며 설치 파일의 해시를 검증합니다.

## 이미지와 번역

[art/provenance.json](art/provenance.json)에 비공개 Forge GPT Image 2.5 Sunburst 생성 모델과 프롬프트를 기록했습니다. 원본 이미지는 `art/source`, 게임용 아틀라스는 모드의 `assets/1x`, `assets/2x`에 있습니다. `tools/prepare_assets.py`로 원본을 원래 Balatro 팔레트의 32/64 픽셀 아틀라스로 변환합니다.

`tools/generate_locales.py`는 한국어·영어를 제외한 13개 번역 파일을 만듭니다. 영어권 픽셀 폰트가 지원하지 않는 가운데점·곡선 아포스트로피는 지원 문자로 변환합니다. 실행 검증은 15개 언어의 목록과 옵션 화면, 카드 중심, 문자별 폰트 지원 여부를 검사합니다.

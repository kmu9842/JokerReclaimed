# Actual game screenshots

The 15 introduction screenshots and 15 illustrated guides were captured from Balatro 1.0.1o with Steamodded 26.829.0, Lovely 0.10.0 and Joker Reclaimed. Each language has five original frames: shop actions, tear confirmation, tear effect, restoration catalogue, and restoration options. The game's HUD is rebuilt in each language before capture.

The guide images place four complete screenshots under localized step captions. Screens are uniformly resized from 1600×900 to 1280×720; no game UI is generated, painted over or reconstructed. Original frames are retained at their full resolution. The game's CRT strength is 0 and bloom is at its minimum for legibility.

The session uses the isolated `Balatro-JRC-QA` save identity, a fixed seeded shop, and example funds of 250 scraps and $45. Tearing the example Common Joker increases the visible balance to 251 scraps. These are documentation fixtures, not a feature of the released mod. Steam integration is disabled in the capture runner; the player's profile and wallet are untouched.

The source screenshots and guide outputs are recorded with SHA-256 hashes in [capture-manifest.json](capture-manifest.json). Game fonts are used locally to render captions and are not redistributed.

## Reproduce when game capture is explicitly requested

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/runtime_test.ps1 -Scenario capture
# Wait for %APPDATA%\Balatro-JRC-QA\capture-report.json to report success.
python tools/build_docs.py
```

The game exits after the capture sequence. `tools/build_docs.py` validates the 100/200 character limits, copies original captures without modifying them, and creates the illustrated guides. Pillow is needed for composition. No AI image service is used for screenshots or guides.

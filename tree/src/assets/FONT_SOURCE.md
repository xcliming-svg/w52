# Noto Sans KR asset provenance

- License: SIL Open Font License 1.1 (`NotoSansKR-LICENSE.txt` in this directory).
- Upstream: https://github.com/google/fonts/tree/main/ofl/notosanskr
- Download during CI: `NotoSansKR[wght].ttf` at upstream is renamed `NotoSansKR-Regular.ttf` for the Godot resource path. The binary is prepared for the export build and must also be downloaded before local use of `tree/src/project.godot`.
- Text license is checked in and included in exported resources.
- This is a bundled open-license font, not the host OS's fallback font. If download fails, CI must fail instead of silently losing Korean glyphs.

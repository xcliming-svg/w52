# w52

Godot 4.x / GDScript / Compatibility renderer starter project.

## Local run

1. Run Godot 4.x.
2. Choose **Import** and select `C:\GPT-Workspace\w52\project.godot`.
3. Press **F5**. A teal circle should move with WASD or arrow keys.

## Web export

The repository includes `export_presets.cfg` with a single-threaded **Web** preset.
Export templates must be installed for the matching Godot editor version.

Headless export command, once Godot is installed:

```powershell
godot --headless --path . --import
New-Item -ItemType Directory -Force build | Out-Null
godot --headless --path . --export-release "Web" build/index.html
```

The export output directory is ignored by Git. A GitHub Actions deployment workflow can be added separately.

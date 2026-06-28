# Release artifacts

Pre-built files are attached to [GitHub Releases](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases).

Build locally:

```powershell
python scripts/patch_ftpm_bios_v2.py
.\scripts\prepare_ezflash_zip.ps1
.\scripts\prepare_windows_package.ps1
.\windows-installer\build_windows_installer.ps1
```

Outputs land in `output/`.
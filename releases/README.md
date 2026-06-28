# Release artifacts (v1.3.1)

Download from [GitHub Releases](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest):

| File | SHA-256 (build 2026-06-28) |
|------|----------------------------|
| `FA506IV_fTPM_Fix_GUI.exe` | `0EEF5BFAB75EB252EE86CC0FB8566E3E9C4D3242902FF1D6A5042E7B67CF85B8` |
| `FA506IV_fTPM_fix_EZFlash_v3.zip` | `BC5EA54BD94FD37E4B45E9CE914BFA3ABF42863F4ABDD956CB11DC45382372B6` |

Build locally:

```powershell
python scripts/patch_ftpm_bios_v3.py
powershell -File scripts/prepare_ezflash_zip.ps1
powershell -File gui/build_gui.ps1
```

Outputs land in `output/` and `releases/` (gitignored binaries).
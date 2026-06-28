# ASUS FA506IV fTPM Fix (Experimental)

Community patch for **ASUS TUF A15 FA506IV** BIOS **320** to address AMD fTPM version **3.42.0.5** (`3.*.0.*`) attestation issues affecting Call of Duty / Warzone (AMD PA-420).

Patches the PSP trustlet **version header** from **3.42.0.5** → **3.42.5.5** (single-byte change). See [docs/TECHNICAL.md](docs/TECHNICAL.md).

> **Disclaimer:** Experimental. Flash at your own risk. May not fully fix attestation. Keep stock BIOS for recovery. Not affiliated with ASUS or AMD.

## Which method is safer?

**EZ Flash (USB) is safer** for this patched ROM — simpler, more direct, fewer failure modes.

| Method | Safety | Convenience |
|--------|--------|-------------|
| **EZ Flash (recommended)** | Safer for modded ROM | Needs USB + BIOS menu |
| **Windows EXE** | Extra steps (driver swap) | No BIOS menu; still requires reboot |

Full comparison: [docs/SAFETY.md](docs/SAFETY.md)

## Quick start (releases)

Download from [Releases](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases):

| File | Use |
|------|-----|
| `FA506IV_fTPM_fix_EZFlash_v2.zip` | **Safest** — extract to FAT32 USB, flash via EZ Flash |
| `FA506IV_fTPM_fix_Windows.exe` | Flash from Windows (reboot required) |

### EZ Flash steps

1. Extract zip to FAT32 USB
2. Verify checksums in `SHA256.txt`
3. BIOS → F2 → Advanced → **ASUS EZ Flash 3**
4. Flash **`FA506IV.320`** (patched)
5. Keep **`FA506IV.320.STOCK`** on USB for rollback

### Windows EXE steps

1. Run **`FA506IV_fTPM_fix_Windows.exe`** as Administrator
2. Confirm model **FA506IV** / BIOS **320**
3. Reboot when prompted (AC power connected)

## Build from source

### 1. Get official ASUS ROM

See [input/README.md](input/README.md). Place stock `FA506IV.320` at `input/stock/FA506IV.320`.

### 2. Patch

```powershell
python scripts/patch_ftpm_bios_v2.py
```

Outputs:

- `output/FA506IV.320` — patched ROM
- `output/ezflash_package/` — EZ Flash package

### 3. Verify

```powershell
python scripts/verify_patch_v2.py
```

### 4. Build Windows EXE (optional)

Requires 7-Zip and ASUS `.cat`/`.inf` in `input/asus-extract/Cabfile/`:

```powershell
.\scripts\prepare_windows_package.ps1
.\windows-installer\build_windows_installer.ps1
```

## After flashing

1. `tpmtool getdeviceinformation`
2. [Activision Secure Attestation Wizard](https://support.activision.com/)
3. Test Warzone (accept `enrollaik.exe` UAC prompt)

`tpm.msc` may still show **3.42.0.5** — that alone does not mean the patch failed.

## Recovery

- **EZ Flash:** flash `FA506IV.320.STOCK` from USB
- **Windows:** run `Rollback_Stock.bat` from the Windows package

## Checksums

```
Stock:   DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched: 51CECB2BF48A58F224C55BB7210BABAED5B97DC72315BEA2CF1D0F26CD94759F
```

## License

MIT — see [LICENSE](LICENSE). ASUS BIOS binaries are **not** redistributed; obtain them from ASUS support.
# ASUS FA506IV fTPM Fix — Warzone TPM 2.0 Attestation (FA506IV BIOS 320)

**Fix Call of Duty / Warzone TPM attestation on ASUS TUF Gaming A15 FA506IV** when fTPM version **3.42.0.5** fails AMD **PA-420** checks.

| | |
|---|---|
| **Problem** | Warzone blocks FA506IV even with TPM 2.0 + Secure Boot enabled |
| **Cause** | AMD fTPM `3.42.0.5` (`3.*.0.*` bad pattern) on BIOS **FA506IV.320** |
| **Fix** | Patch version header **3.42.0.5 → 3.42.5.5** (experimental) |
| **Download** | **[Releases (latest)](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest)** |
| **Website** | **[hesamsamani.github.io/fa506iv-ftpm-fix](https://hesamsamani.github.io/fa506iv-ftpm-fix/)** |

Also known as: *ASUS TUF A15 TPM fix*, *FA506IV Warzone fix*, *FA506IV fTPM 3.42.5.5 patch*, *Ryzen 4800H Warzone TPM*.

> **Disclaimer:** Experimental community project. Not affiliated with ASUS, AMD, or Activision. Flash at your own risk. Keep stock BIOS for recovery.

---

## Download

| File | Best for |
|------|----------|
| [**FA506IV_fTPM_fix_EZFlash_v2.zip**](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest) | **Safest** — USB + ASUS EZ Flash |
| [**FA506IV_fTPM_fix_Windows.exe**](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest) | Flash from Windows (still reboots) |

## Is this my laptop?

- **Model:** ASUS TUF Gaming **A15 FA506IV**
- **BIOS:** **FA506IV.320**
- **CPU:** AMD Ryzen 7 **4800H** (or other Renoir 4000)
- **Check TPM version:** `Win + R` → `tpm.msc` → Manufacturer Version **3.42.0.5**

If all match and Warzone attestation fails → this project is for you.

## Quick start — EZ Flash (recommended)

1. Download **`FA506IV_fTPM_fix_EZFlash_v2.zip`** from [Releases](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest)
2. Extract to a **FAT32** USB drive
3. Verify checksums in `SHA256.txt`
4. Reboot → **F2** → **Advanced** → **ASUS EZ Flash 3**
5. Select **`FA506IV.320`** (patched)
6. Keep **`FA506IV.320.STOCK`** on USB for rollback

## Quick start — Windows EXE

1. Download **`FA506IV_fTPM_fix_Windows.exe`**
2. Run as **Administrator**
3. Confirm **FA506IV** / BIOS **320**
4. Reboot when prompted (**AC power** required)

**EZ Flash is safer** for patched ROMs. See [docs/SAFETY.md](docs/SAFETY.md).

## FAQ

Common searches answered: **[docs/FAQ.md](docs/FAQ.md)**

- Why Warzone blocks FA506IV with TPM enabled
- Official ASUS fix availability
- `tpm.msc` still showing 3.42.0.5 after flash
- Rollback instructions

## After flashing

1. `tpmtool getdeviceinformation`
2. [Activision Secure Attestation Wizard](https://support.activision.com/)
3. Launch Warzone (accept `enrollaik.exe` UAC)

## Build from source

Place official ASUS `FA506IV.320` at `input/stock/` — see [input/README.md](input/README.md).

```powershell
python scripts/patch_ftpm_bios_v2.py
python scripts/verify_patch_v2.py
```

## Technical details

[docs/TECHNICAL.md](docs/TECHNICAL.md) · [docs/SAFETY.md](docs/SAFETY.md)

## Checksums

```
Stock:   DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched: 51CECB2BF48A58F224C55BB7210BABAED5B97DC72315BEA2CF1D0F26CD94759F
```

## License

MIT — [LICENSE](LICENSE). ASUS BIOS binaries are **not** redistributed.
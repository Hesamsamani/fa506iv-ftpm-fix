# ASUS FA506IV fTPM Fix — Warzone TPM 2.0 Attestation (FA506IV BIOS 320)

**Fix Call of Duty / Warzone TPM attestation on ASUS TUF Gaming A15 FA506IV** when fTPM version **3.42.0.5** fails AMD **PA-420** checks.

| | |
|---|---|
| **Problem** | Warzone blocks FA506IV even with TPM 2.0 + Secure Boot enabled |
| **Cause** | AMD fTPM `3.42.0.5` (`3.*.0.*` bad pattern) on BIOS **FA506IV.320** |
| **Fix (v1.3)** | Replace full fTPM trustlet + **EZ Flash USB** (Windows `/fw` cannot flash patched ROM) |
| **Download** | **[Releases (latest)](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest)** |
| **Website** | **[hesamsamani.github.io/fa506iv-ftpm-fix](https://hesamsamani.github.io/fa506iv-ftpm-fix/)** |

> **v1.0.0–v1.2 withdrawn for flashing:** Windows `/fw` ESRT update fails (`0xC0000001`) because `oem96.cat` only signs the stock ROM. Use **v1.3 GUI + EZ Flash USB**.

> **Disclaimer:** Experimental community project. Not affiliated with ASUS, AMD, or Activision. Flash at your own risk. Keep stock BIOS for recovery.

---

## Download (v1.3)

| File | Use |
|------|-----|
| **`FA506IV_fTPM_Fix_GUI.exe`** | **Recommended** — cleanup, EZ Flash USB prep, verify, TPM clear, COD wizard |
| **`FA506IV_fTPM_fix_EZFlash_v3.zip`** | Patched `FA506IV.320` + `FA506IV.320.STOCK` for BIOS EZ Flash 3 |

## Is this my laptop?

- **Model:** ASUS TUF Gaming **A15 FA506IV**
- **BIOS:** **FA506IV.320**
- **CPU:** AMD Ryzen 7 **4800H** (Renoir)
- **Check:** `Win + R` → `tpm.msc` → Manufacturer Version **3.42.0.5**

## Quick start — GUI (v1.3)

1. Download **`FA506IV_fTPM_Fix_GUI.exe`** and run **as Administrator**
2. If you already tried `/fw` and it failed → **Cleanup failed flash**
3. **Pre-check** attestation (may already pass without BIOS flash)
4. Insert FAT32 USB → **Prepare EZ Flash USB**
5. Reboot → **F2** → **Advanced** → **ASUS EZ Flash 3** → select `FA506IV.320`
6. **Verify flash** → **Clear TPM** → **Open COD Wizard**

**Do not use Windows `/fw` reboot** — it cannot apply the patched ROM on FA506IV.

## EZ Flash only (no GUI)

1. Download **`FA506IV_fTPM_fix_EZFlash_v3.zip`**
2. Extract to FAT32 USB root
3. EZ Flash `FA506IV.320` from BIOS

## Rollback

- **USB:** EZ Flash **`FA506IV.320.STOCK`** (included in EZ Flash zip)
- **GUI:** **Rollback stock BIOS**

## FAQ

[docs/FAQ.md](docs/FAQ.md) · [docs/SAFETY.md](docs/SAFETY.md) · [docs/TECHNICAL.md](docs/TECHNICAL.md)

## Build from source

Place official ASUS `FA506IV.320` at `input/stock/`.

```powershell
python scripts/patch_ftpm_bios_v3.py
powershell -File scripts/prepare_ezflash_zip.ps1
powershell -File gui/build_gui.ps1
```

## Checksums (v3 trustlet)

```
Stock:      DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched v3: 37ED09073A01F2C6892603231BC9AB72164734ADD9D1D78A4D58E60E2049C316
```

## License

MIT — [LICENSE](LICENSE). ASUS BIOS binaries are **not** redistributed in the git repo; release packages include patched ROMs built from your stock image.
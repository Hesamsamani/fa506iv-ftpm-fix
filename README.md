# ASUS FA506IV fTPM Fix — Warzone TPM 2.0 Attestation (FA506IV BIOS 320)

**Fix Call of Duty / Warzone TPM attestation on ASUS TUF Gaming A15 FA506IV** when fTPM version **3.42.0.5** fails AMD **PA-420** checks.

| | |
|---|---|
| **Problem** | Warzone blocks FA506IV even with TPM 2.0 + Secure Boot enabled |
| **Cause** | AMD fTPM `3.42.0.5` (`3.*.0.*` bad pattern) on BIOS **FA506IV.320** |
| **Fix (v1.1.0)** | Replace full fTPM trustlet → runtime class **3.42.2.5** (not `3.*.0.*`) |
| **Download** | **[Releases (latest)](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest)** |
| **Website** | **[hesamsamani.github.io/fa506iv-ftpm-fix](https://hesamsamani.github.io/fa506iv-ftpm-fix/)** |

> **v1.0.0 withdrawn:** header-only patch did **not** change `tpm.msc` or pass attestation. Use **v1.1.0+** only.

> **Disclaimer:** Experimental community project. Not affiliated with ASUS, AMD, or Activision. Flash at your own risk. Keep stock BIOS for recovery.

---

## Download

| File | Use |
|------|-----|
| [**FA506IV_fTPM_fix_Windows.exe**](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest) | **Apply patch** (recommended) |
| `FA506IV_fTPM_fix_EZFlash_v2.zip` | **Rollback only** — EZ Flash rejects modified ROMs |

## Is this my laptop?

- **Model:** ASUS TUF Gaming **A15 FA506IV**
- **BIOS:** **FA506IV.320**
- **CPU:** AMD Ryzen 7 **4800H** (Renoir)
- **Check:** `Win + R` → `tpm.msc` → Manufacturer Version **3.42.0.5**

## Quick start — Windows installer (v1.1.0)

1. Download and extract **`FA506IV_fTPM_fix_Windows.exe`**
2. **Right-click `Install.bat` → Run as administrator**
3. Reboot when prompted (**AC power**, do not interrupt)
4. Run **`post_flash_tpm.ps1`** as Administrator (clears TPM)
5. Reboot again
6. Re-run **Call of Duty Secure Attestation Wizard**

Expected after success: `Get-Tpm` shows a version **other than 3.42.0.5** (e.g. **3.42.92.5** / `05025c03` class).

## Rollback

- **Windows:** `Rollback_Stock.bat` as Administrator → reboot
- **USB:** EZ Flash **`FA506IV.320.STOCK`** (FAT32 root)

## FAQ

[docs/FAQ.md](docs/FAQ.md) · [docs/SAFETY.md](docs/SAFETY.md) · [docs/TECHNICAL.md](docs/TECHNICAL.md)

## Build from source

Place official ASUS `FA506IV.320` at `input/stock/`.

```powershell
python scripts/patch_ftpm_bios_v3.py
```

## Checksums (v1.1.0)

```
Stock:      DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched v3: 37ED09073A01F2C6892603231BC9AB72164734ADD9D1D78A4D58E60E2049C316
```

## License

MIT — [LICENSE](LICENSE). ASUS BIOS binaries are **not** redistributed.
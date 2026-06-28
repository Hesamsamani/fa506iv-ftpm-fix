---
title: ASUS FA506IV fTPM Fix for Warzone
description: Fix TPM 2.0 attestation on ASUS TUF A15 FA506IV for Call of Duty Warzone. AMD PA-420 fTPM 3.42.0.5 patch.
permalink: /
---

# ASUS FA506IV fTPM Fix — Warzone & TPM 2.0 Attestation

**The community fix for ASUS TUF Gaming A15 FA506IV** when Call of Duty / Warzone blocks you despite TPM 2.0 and Secure Boot being enabled.

## The problem

- Laptop: **ASUS TUF A15 FA506IV**
- BIOS: **FA506IV.320**
- fTPM version: **3.42.0.5** (bad pattern `3.*.0.*` per **AMD PA-420**)
- Symptom: Warzone / COD secure attestation fails

## The fix

Patch fTPM version header **3.42.0.5 → 3.42.5.5** on official BIOS 320.

## Download now

**[Latest release →](https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest)**

| File | Method |
|------|--------|
| `FA506IV_fTPM_fix_EZFlash_v2.zip` | **Recommended** — USB + ASUS EZ Flash |
| `FA506IV_fTPM_fix_Windows.exe` | Windows installer (reboot required) |

## Quick steps (EZ Flash)

1. Download and extract zip to **FAT32 USB**
2. Reboot → **F2** → **ASUS EZ Flash 3**
3. Flash **`FA506IV.320`**
4. Keep **`FA506IV.320.STOCK`** for rollback

## More information

- [Full README on GitHub](https://github.com/Hesamsamani/fa506iv-ftpm-fix)
- [FAQ — common Warzone TPM questions](https://github.com/Hesamsamani/fa506iv-ftpm-fix/blob/master/docs/FAQ.md)
- [Which flash method is safer?](https://github.com/Hesamsamani/fa506iv-ftpm-fix/blob/master/docs/SAFETY.md)

> Experimental. Not affiliated with ASUS, AMD, or Activision. Flash at your own risk.
# FAQ — ASUS FA506IV fTPM / Warzone / TPM 2.0

Answers to the most common searches about this laptop and the fTPM attestation problem.

## Warzone / Call of Duty

### Why can't I play Warzone on ASUS TUF A15 FA506IV?

Call of Duty requires **TPM 2.0** and **Secure Boot**, plus passing **secure attestation**. On FA506IV with AMD fTPM version **3.42.0.5**, attestation often fails because of AMD **PA-420** — versions matching `3.*.0.*` are rejected even when TPM is enabled.

### I have TPM 2.0 enabled but Warzone still blocks me. Why?

Enabling TPM in BIOS is not enough. Activision checks **fTPM firmware version and attestation**. FA506IV BIOS 320 ships fTPM **3.42.0.5**, which is in the bad pattern. You need **3.42.5.5** or an official ASUS/AMD fix (not released for FA506IV as of 2026).

### Does this fix work for Call of Duty / Warzone on FA506IV?

This project patches the BIOS fTPM **version header** from 3.42.0.5 → 3.42.5.5. It may help attestation, but it is **experimental** and **not guaranteed** — the signed fTPM binary is not replaced.

### Where do I download the FA506IV Warzone TPM fix?

**Official release (recommended):**  
https://github.com/Hesamsamani/fa506iv-ftpm-fix/releases/latest

Files:
- `FA506IV_fTPM_fix_EZFlash_v2.zip` — safest (USB + EZ Flash)
- `FA506IV_fTPM_fix_Windows.exe` — flash from Windows

## Hardware / BIOS

### Which laptops does this support?

Only **ASUS TUF Gaming A15 FA506IV** with BIOS **FA506IV.320** (Ryzen 7 4800H / Renoir). Do not use on other models.

### Is there an official ASUS BIOS fix for FA506IV fTPM?

ASUS has not released a newer FA506IV BIOS after 320 with an official fTPM fix. Contact ASUS support citing **AMD PA-420** and request a firmware update.

### EZ Flash or Windows EXE — which is safer?

**EZ Flash (USB) is safer** for this patched ROM. See [SAFETY.md](SAFETY.md).

## After patching

### tpm.msc still shows 3.42.0.5 after flash. Did it fail?

Not necessarily. This patch changes a PSP header field; Windows may still report the old version. Use **Activision Secure Attestation Wizard** and `tpmtool getdeviceinformation` as success checks.

### How do I roll back to stock BIOS?

Flash `FA506IV.320.STOCK` via EZ Flash, or run `Rollback_Stock.bat` from the Windows package.

## Search terms this project addresses

- ASUS FA506IV TPM fix
- FA506IV Warzone TPM 2.0
- FA506IV fTPM 3.42.0.5 fix
- ASUS TUF A15 TPM attestation failed
- AMD PA-420 FA506IV
- FA506IV BIOS 320 fTPM patch
- Call of Duty TPM error FA506IV
- Ryzen 4800H fTPM Warzone
# Release v1.1.0 — FA506IV fTPM fix (trustlet v3)

## Why v1.0.0 is withdrawn

v1.0.0 used a **header-only** patch (`3.42.0.5 → 3.42.5.5`). That changes one byte in the BIOS file but **does not update the running AMD fTPM firmware**. Users still saw:

- `Get-Tpm` / `tpm.msc` → **ManufacturerVersion 3.42.0.5**
- Call of Duty Secure Attestation Wizard → **BIOS Firmware Update Required**

v1.0.0 is **deprecated and removed** from releases.

## What v1.1.0 does

Replaces the full **PSP_BOOT_TIME_TRUSTLETS** blob (131328 bytes) with a Renoir-compatible trustlet reporting **3.42.2.5** (`05025c03`) — outside AMD PA-420 bad pattern `3.*.0.*`.

| ROM | SHA-256 |
|-----|---------|
| Stock `FA506IV.320` | `DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273` |
| Patched v3 | `37ED09073A01F2C6892603231BC9AB72164734ADD9D1D78A4D58E60E2049C316` |

## Install (Windows only)

1. `FA506IV_fTPM_fix_Windows.exe` → extract → **Run `Install.bat` as Administrator**
2. Reboot (AC power, do not interrupt)
3. Run **`post_flash_tpm.ps1`** as Administrator (Clear TPM)
4. Reboot again
5. Re-run **Call of Duty Secure Attestation Wizard**

## Fixes included

- Windows installer **TrustedInstaller ACL** unlock (`takeown` / `icacls`) before ROM swap
- Honest docs: **EZ Flash rejects modified ROMs** on FA506IV

## Rollback

`Rollback_Stock.bat` + reboot, or EZ Flash `FA506IV.320.STOCK` from USB.
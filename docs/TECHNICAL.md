# Technical details

## Problem

AMD fTPM versions matching `3.*.0.*` (e.g. **3.42.0.5**) fail attestation checks used by Call of Duty / Warzone (AMD PA-420). Target header version: **3.42.5.5**.

## Supported hardware

- **Model:** ASUS TUF Gaming A15 **FA506IV**
- **BIOS base:** **FA506IV.320** (June 2022)
- **CPU:** AMD Ryzen 4000 (Renoir) with AMD fTPM

## Patch (v1.1.0 — trustlet replacement)

Replaces the full PSP boot-time trustlet region:

| Field | Value |
|-------|-------|
| Trustlet region | `0x393200` (131328 bytes) |
| Version offset | `0x393260` |
| Stock version | `05 00 2a 03` (3.42.0.5 — PA-420 bad) |
| Patched version | `05 02 5c 03` (3.42.2.5 class — not `3.*.0.*`) |

v1.0.0 header-only patch (`05 05 2a 03`) is **withdrawn** — it did not change runtime TPM version.

## Checksums

```
Stock:      DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched v3: 37ED09073A01F2C6892603231BC9AB72164734ADD9D1D78A4D58E60E2049C316
```

## Limitations

- Experimental trustlet swap from a Renoir-compatible source BIOS
- Not re-signed by ASUS/AMD
- EZ Flash rejects modified ROMs — use Windows installer
- Clear TPM after flash (`scripts/post_flash_tpm.ps1`)
- Verify with Activision Secure Attestation Wizard

## Windows installer internals

1. `pnputil` installs the **stock** signed ASUS firmware driver (catalog matches stock ROM)
2. Patched ROM overwrites `C:\Windows\Firmware\{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}\FA506IV.320`
3. Reboot triggers Windows firmware update with the staged patched file
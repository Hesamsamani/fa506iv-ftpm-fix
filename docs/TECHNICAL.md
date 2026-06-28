# Technical details

## Problem

AMD fTPM versions matching `3.*.0.*` (e.g. **3.42.0.5**) fail attestation checks used by Call of Duty / Warzone (AMD PA-420). Target header version: **3.42.5.5**.

## Supported hardware

- **Model:** ASUS TUF Gaming A15 **FA506IV**
- **BIOS base:** **FA506IV.320** (June 2022)
- **CPU:** AMD Ryzen 4000 (Renoir) with AMD fTPM

## Patch

Single-byte change in PSP boot-time trustlet version header:

| Field | Value |
|-------|-------|
| Trustlet region | `0x393200` (131328 bytes) |
| Version offset | `0x393260` |
| Change | `05 00 2a 03` → `05 05 2a 03` |
| Byte index | `0x393261`: `0x00` → `0x05` |

## Checksums

```
Stock:   DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched: 51CECB2BF48A58F224C55BB7210BABAED5B97DC72315BEA2CF1D0F26CD94759F
```

## Limitations

- Header-only patch; does not replace AMD's signed fTPM firmware binary
- PSP trustlet signature is not re-signed by ASUS/AMD
- `tpm.msc` may still show **3.42.0.5** after flash
- Use Activision Secure Attestation Wizard and `tpmtool getdeviceinformation` to verify

## Windows installer internals

1. `pnputil` installs the **stock** signed ASUS firmware driver (catalog matches stock ROM)
2. Patched ROM overwrites `C:\Windows\Firmware\{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}\FA506IV.320`
3. Reboot triggers Windows firmware update with the staged patched file
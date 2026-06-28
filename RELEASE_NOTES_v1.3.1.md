# v1.3.1 — EZ Flash primary, GUI redesign, Windows /fw removed

## Breaking change

**Windows `/fw` ESRT flash does not work** for the patched ROM on FA506IV. The signed catalog (`oem96.cat`) only covers the stock ASUS image. Failed attempts show `LastAttemptStatus 0xC0000001` and `ResourcesPhase 2`.

## What changed

- **GUI v1.3.1** with ASUS TUF + gaming hero banner and custom app icon
- **EZ Flash v3 zip** as the primary hardware flash path
- **Cleanup failed flash** button for post-`/fw` recovery
- **Prepare EZ Flash USB** copies patched + stock ROMs to FAT32 drive
- `/fw` reboot blocked in GUI with explanation
- COD attestation pre-check accepts Windows TPM health **Attestable**
- Payload auto-refresh when GUI version changes

## Downloads

| Asset | Description |
|-------|-------------|
| `FA506IV_fTPM_Fix_GUI.exe` | Guided installer (recommended) |
| `FA506IV_fTPM_fix_EZFlash_v3.zip` | USB EZ Flash package |

## Removed / deprecated

- `FA506IV_fTPM_fix_Windows.exe` — misleading `/fw` path
- `FA506IV_fTPM_fix_EZFlash_v2.zip` — header-only patch era

## Workflow

1. Run GUI as Administrator
2. Cleanup (if `/fw` was already tried)
3. Pre-check attestation
4. Prepare EZ Flash USB → BIOS EZ Flash 3
5. Verify → Clear TPM → COD Wizard
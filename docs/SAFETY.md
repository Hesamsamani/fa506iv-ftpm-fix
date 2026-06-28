# Which flash method to use?

## Recommendation: **Windows installer for the patched ROM**

| Factor | EZ Flash (USB) | Windows installer |
|--------|----------------|-------------------|
| Patched ROM | Often **rejected** ("not a proper BIOS driver") | **Works** (stages ROM via signed ASUS driver) |
| Stock rollback | **Best** — flash `FA506IV.320.STOCK` from FAT32 USB | `Rollback_Stock.bat` + reboot |
| Moving parts | One step in firmware | `pnputil` + ACL unlock + ROM swap + reboot |
| Failure modes | Integrity check rejects modified image | TrustedInstaller ACL (fixed in v1.0.1+), interrupted reboot |
| Recovery | Keep `FA506IV.320.STOCK` on same USB | Run `Rollback_Stock.bat`, then reboot |

## Why EZ Flash rejects the patched file

ASUS EZ Flash validates BIOS integrity before flashing. This patch changes one byte inside the AMD PSP fTPM trustlet. EZ Flash treats that as an invalid BIOS image — even with the correct filename (`FA506IV.320`) and FAT32 USB.

**Use EZ Flash only for stock recovery**, not for applying the patch.

## Windows installer notes

- Run `Install.bat` **as Administrator**
- Installer v1.0.1+ unlocks `C:\Windows\Firmware\{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}\FA506IV.320` with `takeown` / `icacls` before copying the patched ROM
- **AC power required** — never flash on battery only
- **Do not interrupt** reboot while Windows flashes firmware

## Shared risks (both methods)

- **Experimental patch** — may not fix Warzone attestation fully
- **Brick risk** — keep stock ROM for recovery
- **Warranty** — modifying BIOS may affect warranty/support

## Official ASUS stock BIOS

For an **unmodified official ASUS ROM**, either ASUS's Windows updater or EZ Flash is fine. This project patches the ROM, which is why the Windows installer is the primary apply path and EZ Flash is for rollback.
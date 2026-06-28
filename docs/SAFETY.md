# Which flash method is safer?

## Recommendation: **EZ Flash (BIOS menu) is safer** for this patched ROM

| Factor | EZ Flash (USB) | Windows EXE |
|--------|----------------|-------------|
| Transparency | You flash the exact file you put on USB | Uses a two-step trick: signed stock install, then ROM swap before reboot |
| Moving parts | One step in firmware | `pnputil` + driver uninstall/reinstall + file swap + reboot |
| Failure modes | Wrong USB file, interrupted flash | Swap timing, Windows driver state, interrupted reboot |
| Recovery | Keep `FA506IV.320.STOCK` on same USB | Run `Rollback_Stock.bat`, then reboot |
| Best for | **Modified / experimental ROMs** | Convenience when EZ Flash is awkward |

## When is the Windows EXE reasonable?

- You are comfortable with Administrator prompts and reboot-based flashing
- You keep the stock recovery ROM and know how to roll back
- EZ Flash is unavailable (e.g. no USB handy) and you accept the extra complexity

## When is EZ Flash better?

- **First time flashing this patch** (recommended)
- You want the simplest, most direct path: one file → one flash
- You want the same method most BIOS mod guides recommend for custom ROMs

## Shared risks (both methods)

- **AC power required** — never flash on battery only
- **Do not interrupt** power or reboot during the flash
- **Experimental patch** — may not fix Warzone attestation fully
- **Brick risk** — keep stock ROM for recovery
- **Warranty** — modifying BIOS may affect warranty/support

## Official ASUS stock BIOS

For an **unmodified official ASUS ROM**, the Windows installer ASUS ships is equally safe — it is their intended update path. This project patches the ROM, which is why EZ Flash is the safer default.
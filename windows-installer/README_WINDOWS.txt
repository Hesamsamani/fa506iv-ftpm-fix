ASUS FA506IV fTPM Fix — Windows Installer
=========================================

Flash from Windows without opening the BIOS EZ Flash menu.
You still must REBOOT — the BIOS is written during restart.

HOW IT WORKS
------------
1. Uses the official ASUS-signed driver package (stock ROM) so Windows accepts the install.
2. Replaces the staged firmware file with the patched ROM before reboot.
3. Windows flashes the patched ROM automatically on restart.

REQUIREMENTS
------------
- ASUS TUF A15 FA506IV with BIOS FA506IV.320
- Windows 10/11, UEFI boot
- Administrator account
- AC power connected

FILES
-----
- Install.bat / FA506IV_fTPM_fix_Windows.exe  Run installer
- Rollback_Stock.bat                          Restore stock BIOS
- FA506IV.320.PATCHED                         Patched ROM (fTPM header fix)
- FA506IV.320.STOCK                           Original ASUS ROM
- Cabfile\                                    Signed stock driver package

USAGE
-----
1. Double-click FA506IV_fTPM_fix_Windows.exe (or Install.bat as Administrator).
2. Confirm model/BIOS info shown in the console.
3. Choose Y to reboot when prompted.
4. Do not power off during restart/flash.

AFTER REBOOT
------------
1. Run COD Secure Attestation Wizard.
2. Run: tpmtool getdeviceinformation
3. Test Warzone (accept enrollaik.exe UAC prompt).

ROLLBACK
--------
Run Rollback_Stock.bat as Administrator, then reboot.

LIMITATIONS
-----------
- Experimental header-only patch; full attestation not guaranteed.
- tpm.msc may still show 3.42.0.5.
- Same brick risk as any BIOS flash — keep stock ROM for recovery.

CHECKSUMS
---------
Stock:   DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
Patched: 51CECB2BF48A58F224C55BB7210BABAED5B97DC72315BEA2CF1D0F26CD94759F
# Input files (not included in git)

Download the official ASUS BIOS update for **FA506IV version 320** from ASUS support:

https://www.asus.com/supportonly/fa506iv/helpdesk_bios/

1. Download `ASUS_FA506IV_320_BIOS_Update_3.exe`
2. Extract with 7-Zip (right-click → 7-Zip → Extract)
3. Copy `Cabfile/FA506IV.320` to:

```
input/stock/FA506IV.320
```

4. For the Windows installer, also extract these from the same ASUS package into `input/asus-extract/Cabfile/`:

- `FA506IV.320` (stock)
- `FA506IV_320.cat`
- `FA506IV_320.inf`

Expected stock SHA-256:

```
DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273
```
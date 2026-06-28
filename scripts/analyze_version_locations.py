"""Find all fTPM version-related byte patterns in BIOS ROM and trustlets."""
from __future__ import annotations

import hashlib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
STOCK = REPO / "input/stock/FA506IV.320"
V3 = REPO / "output/FA506IV.320"
ASUS_T = Path(r"C:\Users\hesam\Downloads\bios-tpm-work\asus-trustlet-original.bin")
LENOVO_T = Path(r"C:\Users\hesam\Downloads\bios-tpm-work\lenovo-trustlet")
STAGED = Path(r"C:\Windows\Firmware\{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}\FA506IV.320")

TRUSTLET_OFFSET = 0x393200
VERSION_OFFSET = 0x393260

PATTERNS = [
    (bytes.fromhex("05002a03"), "bad_ver_dword"),
    (bytes.fromhex("05052a03"), "v2_ver_dword"),
    (bytes.fromhex("05025c03"), "v3_ver_dword"),
    (b"3.42.0.5", "ascii_34205"),
    (b"3.42.2.5", "ascii_34225"),
    (b"3.42.5.5", "ascii_34255"),
    (b"3.42.92.5", "ascii_342925"),
]


def find_all(data: bytes, pat: bytes, limit: int = 20) -> list[int]:
    out: list[int] = []
    start = 0
    while True:
        i = data.find(pat, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
        if len(out) >= limit:
            break
    return out


def report_file(label: str, path: Path) -> None:
    if not path.exists():
        print(f"\n=== {label}: MISSING {path}")
        return
    data = path.read_bytes()
    sha = hashlib.sha256(data).hexdigest().upper()
    print(f"\n=== {label} ===")
    print(f"path: {path}")
    print(f"size: {len(data)} sha256: {sha}")
    if len(data) > VERSION_OFFSET + 4:
        print(f"@0x{VERSION_OFFSET:X}: {data[VERSION_OFFSET:VERSION_OFFSET+4].hex()}")
    for pat, name in PATTERNS:
        hits = find_all(data, pat)
        if hits:
            print(f"  {name}: {len(hits)} hit(s) {[hex(h) for h in hits]}")


def compare_trustlets() -> None:
    if not (ASUS_T.exists() and LENOVO_T.exists()):
        return
    a, l = ASUS_T.read_bytes(), LENOVO_T.read_bytes()
    diffs = sum(1 for i in range(len(a)) if a[i] != l[i])
    print(f"\n=== trustlet compare ===")
    print(f"diff bytes: {diffs}/{len(a)}")
    print(f"asus ver@0x60: {a[0x60:0x64].hex()}")
    print(f"lenovo ver@0x60: {l[0x60:0x64].hex()}")
    for pat, name in PATTERNS:
        ah, lh = find_all(a, pat), find_all(l, pat)
        if ah or lh:
            print(f"  {name}: asus={len(ah)} lenovo={len(lh)}")
            if ah:
                print(f"    asus offsets: {[hex(h) for h in ah[:8]]}")
            if lh:
                print(f"    lenovo offsets: {[hex(h) for h in lh[:8]]}")


def main() -> None:
    for label, path in [
        ("STOCK", STOCK),
        ("V3_PATCHED", V3),
        ("STAGED_WINDOWS", STAGED),
    ]:
        report_file(label, path)
    compare_trustlets()


if __name__ == "__main__":
    main()
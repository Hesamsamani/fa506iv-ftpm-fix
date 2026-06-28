"""Verification suite for FA506IV fTPM patch v2."""

from __future__ import annotations

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

STOCK_SHA = "DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273"
PATCHED_SHA = "51CECB2BF48A58F224C55BB7210BABAED5B97DC72315BEA2CF1D0F26CD94759F"
OLD_VERSION = bytes.fromhex("05002a03")
NEW_VERSION = bytes.fromhex("05052a03")
ROM_SIZE = 0x1000800
VERSION_OFFSET = 0x393260
TRUSTLET_OFFSET = 0x393200
TRUSTLET_SIZE = 0x20100
PS1_MAGIC = b"$PS1"
ZIP_REQUIRED = {"FA506IV.320", "FA506IV.320.STOCK", "FLASH_README.txt", "SHA256.txt"}


def check(name: str, ok: bool, detail: str = "") -> bool:
    status = "PASS" if ok else "FAIL"
    print(f"[{status}] {name}" + (f" — {detail}" if detail else ""))
    return ok


def verify_patched_semantics(stock_data: bytes, patched: bytes, results: list[bool]) -> None:
    diffs = [i for i, (a, b) in enumerate(zip(stock_data, patched)) if a != b]
    results.append(check("exactly one byte changed", len(diffs) == 1, str(diffs)))
    results.append(
        check(
            "diff at version minor byte",
            len(diffs) == 1 and diffs[0] == VERSION_OFFSET + 1,
            f"diffs={diffs}",
        )
    )
    results.append(check("version dword", patched[VERSION_OFFSET : VERSION_OFFSET + 4] == NEW_VERSION))
    results.append(
        check(
            "$PS1 anchor",
            patched[VERSION_OFFSET - 0x50 : VERSION_OFFSET - 0x50 + 4] == PS1_MAGIC,
        )
    )
    results.append(
        check(
            "old version absent / new unique",
            patched.count(OLD_VERSION) == 0 and patched.count(NEW_VERSION) == 1,
        )
    )


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=repo)
    args = parser.parse_args()
    root = args.repo_root

    stock = root / "input" / "stock" / "FA506IV.320"
    patched = root / "output" / "FA506IV.320"
    pkg = root / "output" / "ezflash_package"
    zip_path = root / "output" / "FA506IV_fTPM_fix_EZFlash_v2.zip"

    results: list[bool] = []
    if not stock.exists():
        print(f"[FAIL] stock ROM missing: {stock}")
        print("Place official ASUS FA506IV.320 at input/stock/FA506IV.320")
        return 1

    stock_data = stock.read_bytes()
    results.append(check("stock size", len(stock_data) == ROM_SIZE))
    results.append(check("stock sha256", hashlib.sha256(stock_data).hexdigest().upper() == STOCK_SHA))

    if not patched.exists():
        results.append(check("patched ROM exists", False))
        return 1

    patched_data = patched.read_bytes()
    results.append(check("patched size", len(patched_data) == ROM_SIZE))
    results.append(
        check("patched sha256", hashlib.sha256(patched_data).hexdigest().upper() == PATCHED_SHA)
    )
    verify_patched_semantics(stock_data, patched_data, results)

    sys.path.insert(0, str(root / "scripts"))
    import patch_ftpm_bios_v2 as p2

    forward = bytearray(stock_data)
    off = p2.discover_version_offset(forward)
    p2.validate_preflight(forward, off)
    p2.patch_bios(forward, off)
    results.append(
        check(
            "forward patch sha256",
            hashlib.sha256(bytes(forward)).hexdigest().upper() == PATCHED_SHA,
        )
    )

    if pkg.exists():
        results.append(
            check(
                "package patched ROM",
                (pkg / "Cabfile" / "FA506IV.320").read_bytes() == patched_data,
            )
        )
        results.append(
            check(
                "package stock ROM",
                (pkg / "Cabfile" / "FA506IV.320.STOCK").read_bytes() == stock_data,
            )
        )

    if zip_path.exists():
        with zipfile.ZipFile(zip_path) as zf:
            names = set(zf.namelist())
            results.append(check("zip entries", names == ZIP_REQUIRED, str(sorted(names))))
            results.append(check("zip patched ROM", zf.read("FA506IV.320") == patched_data))

    return 0 if all(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
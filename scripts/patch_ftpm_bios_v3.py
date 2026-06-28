"""
Patch ASUS FA506IV BIOS fTPM trustlet (v3).

Replaces the full PSP_BOOT_TIME_TRUSTLETS blob with a Renoir-compatible
trustlet that reports fTPM version 3.42.2.5 (outside AMD PA-420 3.*.0.*).

Header-only v2 patches are retained for reference but do not change tpm.msc.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INPUT_DIR = REPO_ROOT / "input"
OUTPUT_DIR = REPO_ROOT / "output"

EXPECTED_ROM_SIZE = 0x1000800
EXPECTED_ROM_SHA256 = (
    "DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273"
)
EXPECTED_V3_SHA256 = (
    "37ED09073A01F2C6892603231BC9AB72164734ADD9D1D78A4D58E60E2049C316"
)

TRUSTLET_OFFSET = 0x393200
TRUSTLET_SIZE = 0x20100
VERSION_OFFSET = 0x393260
PS1_OFFSET_IN_TRUSTLET = 0x10
PS1_MAGIC = b"$PS1"
BAD_VERSION = bytes.fromhex("05002a03")
V3_VERSION = bytes.fromhex("05025c03")

DEFAULT_STOCK = INPUT_DIR / "stock" / "FA506IV.320"
DEFAULT_TRUSTLET = INPUT_DIR / "trustlet" / "lenovo-ftpm-trustlet.bin"
DEFAULT_OUTPUT_ROM = OUTPUT_DIR / "FA506IV.320"
DEFAULT_OUTPUT_PACKAGE = OUTPUT_DIR / "ezflash_package"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def validate_trustlet_blob(blob: bytes) -> int:
    if len(blob) != TRUSTLET_SIZE:
        raise ValueError(f"Trustlet must be {TRUSTLET_SIZE} bytes, got {len(blob)}")
    ps1 = blob.find(PS1_MAGIC)
    if ps1 != PS1_OFFSET_IN_TRUSTLET:
        raise ValueError(f"Trustlet $PS1 at 0x{ps1:X}, expected 0x{PS1_OFFSET_IN_TRUSTLET:X}")
    version = blob[0x60 : 0x64]
    if version == BAD_VERSION:
        raise ValueError("Replacement trustlet still contains bad version 3.42.0.5")
    if version[1] == 0x00 and version[2] == 0x2A:
        raise ValueError("Replacement trustlet still matches 3.*.0.* pattern")
    return bytes(blob[0x60:0x64])


def patch_bios_v3(data: bytearray, trustlet: bytes) -> list[str]:
    if len(data) != EXPECTED_ROM_SIZE:
        raise ValueError(f"Unexpected ROM size: {len(data)}")
    version_bytes = validate_trustlet_blob(trustlet)
    data[TRUSTLET_OFFSET : TRUSTLET_OFFSET + TRUSTLET_SIZE] = trustlet
    current = bytes(data[VERSION_OFFSET : VERSION_OFFSET + 4])
    if current != version_bytes:
        raise ValueError(f"Post-replace version mismatch: {current.hex()} != {version_bytes.hex()}")
    if data.count(BAD_VERSION) != 0:
        raise ValueError("Stock bad version dword still present after trustlet replace")
    return [
        f"Replaced full trustlet at 0x{TRUSTLET_OFFSET:X} ({TRUSTLET_SIZE} bytes)",
        f"fTPM version header now {current.hex()} (3.42.2.5 class, not 3.*.0.*)",
    ]


def build_output_tree(stock_rom: bytes, patched_rom: bytes, out_root: Path, changes: list[str]) -> None:
    if out_root.exists():
        shutil.rmtree(out_root)
    out_root.mkdir(parents=True)
    cab = out_root / "Cabfile"
    cab.mkdir(parents=True)
    (cab / "FA506IV.320").write_bytes(patched_rom)
    (cab / "FA506IV.320.STOCK").write_bytes(stock_rom)
    stock_sha = sha256_hex(stock_rom)
    patched_sha = sha256_hex(patched_rom)
    (out_root / "SHA256.txt").write_text(
        "\n".join(
            [
                f"FA506IV.320.STOCK {stock_sha}",
                f"FA506IV.320       {patched_sha}",
            ]
        ),
        encoding="utf-8",
    )
    (out_root / "FLASH_README.txt").write_text(
        "\n".join(
            [
                "ASUS FA506IV fTPM Fix v3 (Trustlet replacement)",
                "==============================================",
                "",
                "USE WINDOWS INSTALLER (EZ Flash rejects modified ROMs).",
                "",
                "This v3 package replaces the full AMD fTPM trustlet blob.",
                "Target runtime version class: 3.42.2.5 (not 3.*.0.*).",
                "",
                f"Stock SHA-256:   {stock_sha}",
                f"Patched SHA-256: {patched_sha}",
                "",
                "Actions:",
                *[f"  - {line}" for line in changes],
                "",
                "After flash:",
                "1. Reboot twice if RestartPending stays true.",
                "2. Run scripts/post_flash_tpm.ps1 (Clear TPM).",
                "3. Re-run Call of Duty Secure Attestation Wizard.",
            ]
        ),
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="ASUS FA506IV fTPM BIOS patcher v3")
    parser.add_argument("--stock", type=Path, default=DEFAULT_STOCK)
    parser.add_argument("--trustlet", type=Path, default=DEFAULT_TRUSTLET)
    parser.add_argument("--output-rom", type=Path, default=DEFAULT_OUTPUT_ROM)
    parser.add_argument("--output-package", type=Path, default=DEFAULT_OUTPUT_PACKAGE)
    args = parser.parse_args()

    stock_rom = args.stock.read_bytes()
    if sha256_hex(stock_rom) != EXPECTED_ROM_SHA256:
        print("Stock ROM SHA-256 mismatch", file=sys.stderr)
        return 1

    trustlet = args.trustlet.read_bytes()
    data = bytearray(stock_rom)
    changes = patch_bios_v3(data, trustlet)
    patched_rom = bytes(data)
    patched_sha = sha256_hex(patched_rom)
    if patched_sha != EXPECTED_V3_SHA256:
        print(f"Unexpected v3 SHA-256: {patched_sha}", file=sys.stderr)
        return 1

    args.output_rom.parent.mkdir(parents=True, exist_ok=True)
    args.output_rom.write_bytes(patched_rom)
    build_output_tree(stock_rom, patched_rom, args.output_package, changes)

    print("Patch v3 complete:")
    for line in changes:
        print(f"  - {line}")
    print(f"Patched ROM: {args.output_rom}")
    print(f"Patched SHA: {patched_sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
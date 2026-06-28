"""
Patch ASUS FA506IV BIOS fTPM trustlet version header (v2).

Target: 3.42.0.5 (05 00 2a 03) -> 3.42.5.5 (05 05 2a 03)
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

TRUSTLET_OFFSET = 0x393200
TRUSTLET_SIZE = 0x20100
VERSION_OFFSET_FALLBACK = 0x393260
PS1_OFFSET_IN_TRUSTLET = 0x10
PS1_MAGIC = b"$PS1"
OLD_VERSION = bytes.fromhex("05002a03")
NEW_VERSION = bytes.fromhex("05052a03")
VERSION_PREFIX = bytes.fromhex("05002a03ffffffff")

DEFAULT_STOCK = INPUT_DIR / "stock" / "FA506IV.320"
DEFAULT_OUTPUT_PACKAGE = OUTPUT_DIR / "ezflash_package"
DEFAULT_OUTPUT_ROM = OUTPUT_DIR / "FA506IV.320"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def discover_version_offset(data: bytes) -> int:
    idx = data.find(VERSION_PREFIX)
    if idx != -1:
        return idx
    return VERSION_OFFSET_FALLBACK


def validate_preflight(data: bytes, version_offset: int) -> None:
    if len(data) != EXPECTED_ROM_SIZE:
        raise ValueError(
            f"Unexpected ROM size: {len(data)} bytes (expected {EXPECTED_ROM_SIZE})"
        )
    if version_offset < 0x50:
        raise ValueError(
            f"Version offset too low for $PS1 anchor: 0x{version_offset:X}"
        )
    if version_offset + 4 > len(data):
        raise ValueError(f"Version offset out of range: 0x{version_offset:X}")
    ps1_offset = version_offset - 0x50
    if data[ps1_offset : ps1_offset + 4] != PS1_MAGIC:
        raise ValueError(
            f"Missing $PS1 magic at 0x{ps1_offset:X} (version offset 0x{version_offset:X})"
        )
    if TRUSTLET_OFFSET + TRUSTLET_SIZE > len(data):
        raise ValueError("Trustlet region exceeds ROM bounds")
    old_count = data.count(OLD_VERSION)
    new_count = data.count(NEW_VERSION)
    if old_count + new_count != 1:
        raise ValueError(
            f"Expected exactly one version dword (old={old_count}, new={new_count})"
        )


def assert_safe_output_paths(source_root: Path, out_root: Path) -> None:
    source_resolved = source_root.resolve()
    out_resolved = out_root.resolve()
    if out_resolved == source_resolved:
        raise ValueError(
            f"--output-package must not equal --source-tree ({out_resolved})"
        )
    try:
        source_resolved.relative_to(out_resolved)
        raise ValueError(
            f"--output-package ({out_resolved}) cannot be an ancestor of "
            f"--source-tree ({source_resolved})"
        )
    except ValueError as exc:
        if "cannot be an ancestor" in str(exc):
            raise


def patch_bios(
    data: bytearray,
    version_offset: int,
    replace_blob: bytes | None = None,
) -> list[str]:
    changes: list[str] = []
    if replace_blob is not None:
        if len(replace_blob) != TRUSTLET_SIZE:
            raise ValueError(
                f"Replacement trustlet must be {TRUSTLET_SIZE} bytes, got {len(replace_blob)}"
            )
        blob_ps1 = replace_blob.find(PS1_MAGIC)
        if blob_ps1 == -1:
            raise ValueError("Replacement trustlet does not contain $PS1 header")
        if blob_ps1 != PS1_OFFSET_IN_TRUSTLET:
            raise ValueError(
                f"Replacement trustlet $PS1 at 0x{blob_ps1:X}, "
                f"expected 0x{PS1_OFFSET_IN_TRUSTLET:X} (FA506IV layout)"
            )
        data[TRUSTLET_OFFSET : TRUSTLET_OFFSET + TRUSTLET_SIZE] = replace_blob
        changes.append(
            f"Replaced full trustlet blob at 0x{TRUSTLET_OFFSET:X} ({TRUSTLET_SIZE} bytes)"
        )
        version_offset = discover_version_offset(data)
        validate_preflight(data, version_offset)

    current = bytes(data[version_offset : version_offset + 4])
    if current == NEW_VERSION:
        if replace_blob is None:
            changes.append(
                f"Already patched at 0x{version_offset:X} ({NEW_VERSION.hex()}) — no changes"
            )
        return changes
    if current != OLD_VERSION:
        raise ValueError(
            f"Unexpected fTPM version at 0x{version_offset:X}: {current.hex()} "
            f"(expected {OLD_VERSION.hex()} or {NEW_VERSION.hex()})"
        )
    data[version_offset : version_offset + 4] = NEW_VERSION
    changes.append(
        "Patched version header only: 3.42.0.5 -> 3.42.5.5 "
        f"(0x{version_offset:X}: {OLD_VERSION.hex()} -> {NEW_VERSION.hex()})"
    )
    return changes


def write_flash_readme(
    path: Path,
    *,
    patched_sha: str,
    stock_sha: str,
    version_offset: int,
    changes: list[str],
) -> None:
    path.write_text(
        "\n".join(
            [
                "ASUS FA506IV fTPM Fix v2 (Experimental)",
                "====================================",
                "",
                "USE EZ FLASH ONLY.",
                "",
                "USB files (FAT32):",
                "  FA506IV.320           -> PATCHED ROM (flash this)",
                "  FA506IV.320.STOCK     -> ORIGINAL ASUS ROM (recovery only)",
                "  SHA256.txt            -> checksums for both ROMs",
                "",
                f"Stock SHA-256:   {stock_sha}",
                f"Patched SHA-256: {patched_sha}",
                f"Version offset:  0x{version_offset:X}",
                "",
                "Patch actions:",
                *[f"  - {line}" for line in changes],
                "",
                "EZ Flash steps:",
                "1. Copy both ROM files to a FAT32 USB drive.",
                "2. Reboot -> F2 -> Advanced -> ASUS EZ Flash 3.",
                "3. Select FA506IV.320 (patched) from USB.",
                "4. Keep AC power connected; do not interrupt.",
                "",
                "Recovery:",
                "1. If boot fails or TPM breaks, EZ Flash FA506IV.320.STOCK from USB.",
                "2. Verify stock SHA matches before rollback.",
                "",
                "Known limitation:",
                "Header-only patch. tpm.msc may still show 3.42.0.5.",
                "Use Activision Secure Attestation Wizard as success criteria.",
            ]
        ),
        encoding="utf-8",
    )


def build_output_tree(
    stock_rom: bytes,
    patched_rom: bytes,
    out_root: Path,
    version_offset: int,
    changes: list[str],
) -> None:
    if out_root.exists():
        shutil.rmtree(out_root)
    out_root.mkdir(parents=True)
    cab = out_root / "Cabfile"
    cab.mkdir(parents=True, exist_ok=True)
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
    write_flash_readme(
        out_root / "FLASH_README.txt",
        patched_sha=patched_sha,
        stock_sha=stock_sha,
        version_offset=version_offset,
        changes=changes,
    )
    (out_root / "DO_NOT_USE_WINDOWS_INSTALLER.txt").write_text(
        "Patched ROM is for EZ Flash only.\n"
        "Use the Windows installer from releases/ if you prefer in-OS flashing.\n",
        encoding="utf-8",
    )


def load_stock_rom(stock_path: Path) -> bytes:
    stock_rom = stock_path.read_bytes()
    stock_sha = sha256_hex(stock_rom)
    if stock_sha != EXPECTED_ROM_SHA256:
        raise ValueError(
            f"Stock ROM SHA-256 mismatch at {stock_path}: {stock_sha} "
            f"(expected {EXPECTED_ROM_SHA256})"
        )
    return stock_rom


def main() -> None:
    parser = argparse.ArgumentParser(description="ASUS FA506IV fTPM BIOS patcher v2")
    parser.add_argument("--input", type=Path, default=DEFAULT_STOCK)
    parser.add_argument("--stock", type=Path, default=DEFAULT_STOCK)
    parser.add_argument("--source-tree", type=Path, default=INPUT_DIR / "asus-extract")
    parser.add_argument("--output-rom", type=Path, default=DEFAULT_OUTPUT_ROM)
    parser.add_argument("--output-package", type=Path, default=DEFAULT_OUTPUT_PACKAGE)
    parser.add_argument("--allow-unknown-input", action="store_true")
    parser.add_argument("--replace-trustlet", type=Path)
    args = parser.parse_args()

    assert_safe_output_paths(args.source_tree, args.output_package)
    stock_rom = load_stock_rom(args.stock)

    input_rom = args.input.read_bytes()
    input_sha = sha256_hex(input_rom)
    if input_sha != EXPECTED_ROM_SHA256 and not args.allow_unknown_input:
        print(
            f"Error: input ROM SHA-256 does not match known stock FA506IV.320.\n"
            f"  Got:      {input_sha}\n"
            f"  Expected: {EXPECTED_ROM_SHA256}\n"
            "Place the official ASUS ROM at input/stock/FA506IV.320",
            file=sys.stderr,
        )
        sys.exit(1)

    data = bytearray(input_rom)
    version_offset = discover_version_offset(data)
    if version_offset != VERSION_OFFSET_FALLBACK:
        print(f"Discovered version offset 0x{version_offset:X}")
    validate_preflight(data, version_offset)

    replace_blob = args.replace_trustlet.read_bytes() if args.replace_trustlet else None
    changes = patch_bios(data, version_offset, replace_blob)
    patched_rom = bytes(data)

    args.output_rom.parent.mkdir(parents=True, exist_ok=True)
    args.output_rom.write_bytes(patched_rom)
    build_output_tree(stock_rom, patched_rom, args.output_package, version_offset, changes)

    print("Patch v2 complete:")
    for line in changes:
        print(f"  - {line}")
    print(f"Patched ROM: {args.output_rom}")
    print(f"Package:     {args.output_package}")
    print(f"Stock SHA-256:   {sha256_hex(stock_rom)}")
    print(f"Patched SHA-256: {sha256_hex(patched_rom)}")


if __name__ == "__main__":
    main()
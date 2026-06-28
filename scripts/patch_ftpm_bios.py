"""
Patch ASUS FA506IV BIOS fTPM trustlet version header.
Target: 3.42.0.5 (05 00 2a 03) -> 3.42.5.5 (05 05 2a 03)

WARNING: This only patches the PSP header version field unless a full
replacement trustlet blob is supplied. Flash at your own risk.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import struct
from pathlib import Path

TRUSTLET_OFFSET = 0x393200
TRUSTLET_SIZE = 0x20100
VERSION_OFFSET = 0x393260
OLD_VERSION = bytes.fromhex("05002a03")
NEW_VERSION = bytes.fromhex("05052a03")


def patch_bios(data: bytearray, replace_blob: bytes | None = None) -> list[str]:
    changes: list[str] = []

    current = bytes(data[VERSION_OFFSET : VERSION_OFFSET + 4])
    if current != OLD_VERSION:
        raise ValueError(
            f"Unexpected fTPM version at 0x{VERSION_OFFSET:X}: {current.hex()} "
            f"(expected {OLD_VERSION.hex()})"
        )

    if replace_blob is not None:
        if len(replace_blob) != TRUSTLET_SIZE:
            raise ValueError(
                f"Replacement trustlet must be {TRUSTLET_SIZE} bytes, got {len(replace_blob)}"
            )
        data[TRUSTLET_OFFSET : TRUSTLET_OFFSET + TRUSTLET_SIZE] = replace_blob
        changes.append(
            f"Replaced full trustlet blob at 0x{TRUSTLET_OFFSET:X} ({TRUSTLET_SIZE} bytes)"
        )
    else:
        data[VERSION_OFFSET : VERSION_OFFSET + 4] = NEW_VERSION
        changes.append(
            "Patched version header only: 3.42.0.5 -> 3.42.5.5 "
            f"(0x{VERSION_OFFSET:X}: {OLD_VERSION.hex()} -> {NEW_VERSION.hex()})"
        )

    return changes


def build_output_tree(source_root: Path, patched_rom: bytes, out_root: Path) -> None:
    if out_root.exists():
        shutil.rmtree(out_root)
    shutil.copytree(source_root, out_root)

    rom_path = out_root / "Cabfile" / "FA506IV.320"
    rom_path.write_bytes(patched_rom)

    sha = hashlib.sha256(patched_rom).hexdigest().upper()
    readme = out_root.parent / "README_FLASH_INSTRUCTIONS.txt"
    readme.write_text(
        "\n".join(
            [
                "ASUS FA506IV fTPM Experimental BIOS Package",
                "===========================================",
                "",
                f"Patched ROM SHA-256: {sha}",
                "",
                "FLASH METHOD (recommended): ASUS EZ Flash",
                "1. Copy FA506IV.320 to a FAT32 USB drive root.",
                "2. Reboot -> hold F2 for BIOS -> EZ Flash -> select file.",
                "3. Do NOT interrupt power during update.",
                "",
                "Recovery plan: keep original FA506IV.320 backup on USB.",
                "",
                "Windows pnputil install may fail because catalog signing no longer matches.",
            ]
        ),
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default=r"C:\Users\hesam\Downloads\bios-tpm-work\asus-bios\zip-contents\Cabfile\FA506IV.320",
    )
    parser.add_argument(
        "--source-tree",
        default=r"C:\Users\hesam\Downloads\bios-tpm-work\asus-bios\zip-contents",
    )
    parser.add_argument(
        "--output-rom",
        default=r"C:\Users\hesam\Downloads\bios-tpm-work\FA506IV_320_fTPM_patched.320",
    )
    parser.add_argument(
        "--output-package",
        default=r"C:\Users\hesam\Downloads\bios-tpm-work\FA506IV_fTPM_fix_package",
    )
    parser.add_argument("--replace-trustlet")
    args = parser.parse_args()

    input_path = Path(args.input)
    data = bytearray(input_path.read_bytes())

    replace_blob = None
    if args.replace_trustlet:
        replace_blob = Path(args.replace_trustlet).read_bytes()

    changes = patch_bios(data, replace_blob)
    output_rom = Path(args.output_rom)
    output_rom.write_bytes(data)

    build_output_tree(Path(args.source_tree), bytes(data), Path(args.output_package))

    print("Patch complete:")
    for line in changes:
        print(f"  - {line}")
    print(f"ROM: {output_rom}")
    print(f"Package: {args.output_package}")
    print(f"SHA-256: {hashlib.sha256(data).hexdigest().upper()}")


if __name__ == "__main__":
    main()
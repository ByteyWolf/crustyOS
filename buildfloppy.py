#!/usr/bin/env python3
import subprocess
import os
import sys

IMAGE = "floppy.img"
STAGE0 = "build/stage0.bin"
STAGE1 = "build/stage1.bin"
FS_DIR = "FLOPPY_FILESYSTEM"

SECTOR_SIZE = 512
TOTAL_SECTORS = 2880
RESERVED_SECTORS = 4

def run(cmd):
    print("+", " ".join(cmd))
    subprocess.check_call(cmd)

def main():
    # 1. Create empty floppy image
    run([
        "dd", "if=/dev/zero",
        f"of={IMAGE}",
        f"bs={SECTOR_SIZE}",
        f"count={TOTAL_SECTORS}"
    ])

    # 2. Write stage0
    run([
        "dd", f"if={STAGE0}",
        f"of={IMAGE}",
        "bs=512", "count=1",
        "conv=notrunc"
    ])

    # 3. Write stage1
    run([
        "dd", f"if={STAGE1}",
        f"of={IMAGE}",
        "bs=512",
        "seek=1",
        f"count={RESERVED_SECTORS - 1}",
        "conv=notrunc"
    ])

    # 4. Format FAT12 starting at sector 4
    run([
        "mkfs.fat",
        "-F", "12",
        "-R", str(RESERVED_SECTORS),
        IMAGE
    ])

    # 5. Copy files into FAT
    for fname in os.listdir(FS_DIR):
        path = os.path.join(FS_DIR, fname)
        if os.path.isfile(path):
            run([
                "mcopy",
                "-i", IMAGE,
                path,
                f"::{fname.upper()}"
            ])

    print("Floppy image built successfully!")

if __name__ == "__main__":
    main()

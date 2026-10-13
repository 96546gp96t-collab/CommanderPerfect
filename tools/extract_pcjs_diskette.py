#!/usr/bin/env python3
"""Extract the files from a PCjs JSON diskette image.

PCjs (pcjs.org) stores old floppy disks as JSON: a list of sectors plus a file
table with an MD5 hash per file. This script rebuilds the raw FAT12 disk,
copies every file in the root directory to the output folder and checks it
against the hash.

Used in cloud sessions to get the Keen 1 shareware files, see CLAUDE.md.

Usage:
    python3 tools/extract_pcjs_diskette.py KEEN1-V11.json game_data/keen1
"""

import hashlib
import json
import struct
import sys
from pathlib import Path

DIRECTORY_ENTRY_SIZE = 32
UNUSED_ENTRY_MARKERS = (0x00, 0xE5)
VOLUME_OR_DIRECTORY_FLAGS = 0x18
FIRST_DATA_CLUSTER = 2
END_OF_CHAIN = 0xFF8


def build_disk_image(diskette: dict) -> bytearray:
    info = diskette["imageInfo"]
    sectors_per_track = info["trackDefault"]
    sector_size = info["sectorDefault"]
    image = bytearray(info["diskSize"])

    for cylinder, heads in enumerate(diskette["diskData"]):
        for head, sectors in enumerate(heads):
            for sector in sectors:
                words = sector["d"]
                word_count = sector["l"] // 4
                # PCjs leaves out repeated values at the end of a sector.
                words = words + [words[-1]] * (word_count - len(words))
                data = b"".join(struct.pack("<i", word) for word in words)
                lba = (cylinder * info["heads"] + head) * sectors_per_track + sector["s"] - 1
                image[lba * sector_size : (lba + 1) * sector_size] = data
    return image


def next_cluster(fat: bytes, cluster: int) -> int:
    """FAT12 packs two 12-bit cluster numbers into three bytes."""
    offset = cluster * 3 // 2
    value = fat[offset] | fat[offset + 1] << 8
    return value >> 4 if cluster & 1 else value & 0xFFF


def extract_root_files(diskette: dict, image: bytearray, output: Path) -> bool:
    volume = diskette["volTable"][0]
    sector_size = diskette["imageInfo"]["sectorDefault"]
    expected_hashes = {f["path"].lstrip("/"): f.get("hash") for f in diskette["fileTable"]}
    fat = image[volume["vbaFAT"] * sector_size :]
    root_start = volume["vbaRoot"] * sector_size
    cluster_size = volume["clusSecs"] * sector_size
    all_ok = True

    for index in range(volume["rootTotal"]):
        entry = image[root_start + index * DIRECTORY_ENTRY_SIZE :][:DIRECTORY_ENTRY_SIZE]
        if entry[0] in UNUSED_ENTRY_MARKERS or entry[11] & VOLUME_OR_DIRECTORY_FLAGS:
            continue

        name = entry[0:8].decode().strip() + "." + entry[8:11].decode().strip()
        cluster = struct.unpack("<H", entry[26:28])[0]
        size = struct.unpack("<I", entry[28:32])[0]
        contents = bytearray()
        while FIRST_DATA_CLUSTER <= cluster < END_OF_CHAIN:
            start = volume["vbaData"] * sector_size + (cluster - FIRST_DATA_CLUSTER) * cluster_size
            contents += image[start : start + cluster_size]
            cluster = next_cluster(fat, cluster)
        contents = bytes(contents[:size])

        hash_ok = hashlib.md5(contents).hexdigest() == expected_hashes.get(name)
        all_ok &= hash_ok
        (output / name).write_bytes(contents)
        print(f"{name:14} {size:7} bytes  {'OK' if hash_ok else 'HASH MISMATCH'}")
    return all_ok


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    diskette = json.loads(Path(sys.argv[1]).read_text())
    output = Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    return 0 if extract_root_files(diskette, build_disk_image(diskette), output) else 1


if __name__ == "__main__":
    sys.exit(main())

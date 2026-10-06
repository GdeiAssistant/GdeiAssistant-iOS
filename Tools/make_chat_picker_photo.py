#!/usr/bin/env python3
"""Make a deterministic, metadata-free photo fixture using only the Python stdlib."""

import hashlib
import json
from pathlib import Path
import struct
import sys
import zlib


def png_chunk(kind, payload):
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def make_photo(output):
    width, height = 480, 320
    pixels = bytearray()
    for y in range(height):
        pixels.append(0)  # PNG row filter: none.
        for x in range(width):
            # Three colored bands and a white upward arrow make rotation/cropping visible.
            colors = ((218, 76, 76), (48, 151, 111), (51, 103, 187))
            color = colors[min(x // 160, 2)]
            shaft = 222 <= x < 258 and 112 <= y < 264
            arrowhead = 56 <= y < 144 and abs(x - 240) <= (y - 56)
            if shaft or arrowhead:
                color = (249, 247, 238)
            if x < 10 or x >= width - 10 or y < 10 or y >= height - 10:
                color = (25, 31, 38)
            pixels.extend(color)

    contents = b"\x89PNG\r\n\x1a\n"
    contents += png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    contents += png_chunk(b"IDAT", zlib.compress(bytes(pixels), level=9))
    contents += png_chunk(b"IEND", b"")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(contents)
    manifest = {
        "file": output.name,
        "width": width,
        "height": height,
        "bytes": len(contents),
        "sha256": hashlib.sha256(contents).hexdigest(),
        "synthetic": True,
        "purpose": "PhotosPicker simulator UI tests; imported with simctl addmedia",
    }
    output.with_suffix(".json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: make_chat_picker_photo.py <output.png>")
    make_photo(Path(sys.argv[1]))

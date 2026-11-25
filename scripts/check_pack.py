"""The web export's size budget (#183). ./export.sh runs it on every export, so CI fails
when the first load grows past the budget.

    python3 -I scripts/check_pack.py <export dir>

Reads index.pck's file list and fails if:
  - index.pck, gzipped as GitHub Pages sends it, is over PCK_BUDGET;
  - it holds a music loop or a voice line (those are in audio.pck, loaded once sound
    is on: game/audio/audio.gd);
  - it holds any of the dev addon godot_mcp_toolkit, or the game would still autoload it;
  - audio.pck is missing, or lacks the music or the voice lines.
Prints the sizes either way: index.pck, index.wasm, the whole first load, audio.pck.
"""
import gzip
import os
import struct
import sys

# Bytes, gzipped. Before #183 index.pck was about 46 MB this way; without the audio and
# the addon it is about 12 MB. Raise the budget only with a reason in the commit.
# 16 MB from FAL-1034: the Dry Flats' ChatGPT board and seven backdrops add 1.2 MB (the CEO's
# size call: whole boards, until the first load passes 30 MB). Each later zone states its own raise.
# 17.4 MB from FAL-1611: the Radio Spires' board and eight backdrops add 1.41 MB as imported.
# 18.73 MB from FAL-1612: the Engine Core's board and eight backdrops add 1.33 MB as imported.
# 19.32 MB from FAL-1613: the Scrap Fields' board (its backdrops were already in) adds 592,522 B as imported.
# The first load is then 29.2 MB, so the next art raise starts the core-plus-bands follow-up.
PCK_BUDGET = 19_322_522
ADDON = "res://addons/godot_mcp_toolkit/"
AUDIO_DIRS = ("res://assets/audio/music/", "res://assets/audio/voice/")


def pack_files(path):
    """{res:// path: bytes} of a Godot 4 PCK (format 2 to 4)."""
    with open(path, "rb") as f:
        data = f.read()
    magic, version, _major, _minor, _patch, flags, base = struct.unpack_from("<4sIIIIIQ", data, 0)
    if magic != b"GDPC" or version < 2:
        raise SystemExit(f"{path}: not a Godot 4 pack")
    if flags & 1:
        raise SystemExit(f"{path}: the directory is encrypted")
    if version >= 3:
        (offset,) = struct.unpack_from("<Q", data, 32)
    else:
        offset = 32 + 16 * 4
    (count,) = struct.unpack_from("<I", data, offset)
    offset += 4
    base_off = base if flags & 2 else 0
    files = {}
    for _ in range(count):
        (length,) = struct.unpack_from("<I", data, offset)
        offset += 4
        name = data[offset:offset + length].rstrip(b"\0").decode()
        offset += length
        start, size = struct.unpack_from("<QQ", data, offset)
        offset += 16 + 16 + 4  # offset, size, md5, flags
        # Format 3 and later store "assets/x.png" for res://assets/x.png
        if not name.startswith("res://"):
            name = "res://" + name
        files[name] = data[base_off + start:base_off + start + size]
    return files


def gz(path):
    with open(path, "rb") as f:
        return len(gzip.compress(f.read(), 6))


def mb(n):
    return f"{n / 1e6:.1f} MB"


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "build/next"
    pck = os.path.join(out, "index.pck")
    audio = os.path.join(out, "audio.pck")
    problems = []

    files = pack_files(pck)
    sources = {name[:-len(".import")] for name in files if name.endswith(".import")}
    sources |= {name[:-len(".remap")] for name in files if name.endswith(".remap")}
    for name in sorted(set(files) | sources):
        if name.startswith(ADDON):
            problems.append(f"index.pck holds the dev addon: {name}")
            break
    for name in sorted(sources):
        if name.startswith(AUDIO_DIRS):
            problems.append(f"index.pck holds {name}: music and voice lines go in audio.pck")
            break
    # The addon's own export plugin drops the autoload; editor_plugins/enabled may still
    # name it, which an export never reads.
    if b"autoload/MCPRuntimeServer" in files.get("res://project.binary", b""):
        problems.append("the exported project still autoloads the dev addon")

    if not os.path.isfile(audio):
        problems.append("no audio.pck beside index.pck")
    else:
        held = {name[:-len(".import")] for name in pack_files(audio) if name.endswith(".import")}
        for d in AUDIO_DIRS:
            if not any(name.startswith(d) for name in held):
                problems.append(f"audio.pck has nothing from {d}")

    first_load = 0
    for name in sorted(os.listdir(out)):
        if name.startswith("index."):
            first_load += gz(os.path.join(out, name))
    pck_gz = gz(pck)
    print(f"index.pck   {mb(os.path.getsize(pck))}, {mb(pck_gz)} gzipped (budget {mb(PCK_BUDGET)})")
    print(f"index.wasm  {mb(gz(os.path.join(out, 'index.wasm')))} gzipped")
    print(f"first load  {mb(first_load)} gzipped (every index.* file)")
    if os.path.isfile(audio):
        print(f"audio.pck   {mb(os.path.getsize(audio))}, once sound is on")
    if pck_gz > PCK_BUDGET:
        problems.append(f"index.pck is {mb(pck_gz)} gzipped, over the {mb(PCK_BUDGET)} budget")

    for p in problems:
        print(f"FAIL {p}", file=sys.stderr)
    if problems:
        sys.exit(1)
    print("ok   web pack within budget")


if __name__ == "__main__":
    main()

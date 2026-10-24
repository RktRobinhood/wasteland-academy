"""Fetch only the single-threaded Web export templates for Godot 4.7.2.

    python3 -I scripts/fetch_web_templates.py <templates dir>

The official templates come as one 1.3 GB archive (.tpz, a zip) with every platform
in it. This reads just the zip index and the two Web members with HTTP range
requests, about 20 MB in all, and writes them into <templates dir>, which Godot
looks for as <data dir>/godot/export_templates/4.7.2.stable/. The zip CRCs check
each file.
"""
import io
import os
import sys
import urllib.request
import zipfile

VERSION = "4.7.2"
URL = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"
MEMBERS = ["templates/version.txt", "templates/web_nothreads_release.zip", "templates/web_nothreads_debug.zip"]
BLOCK = 4 << 20


def final_url(url):
    req = urllib.request.Request(url, method="HEAD")
    with urllib.request.urlopen(req) as r:
        return r.geturl(), int(r.headers["Content-Length"])


class RemoteFile(io.RawIOBase):
    """A read-only, seekable view of a URL, read in BLOCK-sized ranges."""

    def __init__(self, url):
        self.url, self.size = final_url(url)
        self.pos = 0
        self.cache = {}

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, offset, whence=io.SEEK_SET):
        base = {io.SEEK_SET: 0, io.SEEK_CUR: self.pos, io.SEEK_END: self.size}[whence]
        self.pos = base + offset
        return self.pos

    def _block(self, n):
        if n not in self.cache:
            start = n * BLOCK
            end = min(start + BLOCK, self.size) - 1
            req = urllib.request.Request(self.url, headers={"Range": f"bytes={start}-{end}"})
            with urllib.request.urlopen(req) as r:
                if r.status != 206:
                    sys.exit(f"server ignored the range request (HTTP {r.status})")
                self.cache = {n: r.read()}
        return self.cache[n]

    def readinto(self, b):
        want = min(len(b), self.size - self.pos)
        got = 0
        while got < want:
            block = self._block((self.pos + got) // BLOCK)
            off = (self.pos + got) % BLOCK
            chunk = block[off:off + want - got]
            b[got:got + len(chunk)] = chunk
            got += len(chunk)
        self.pos += got
        return got


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    dest = sys.argv[1]
    os.makedirs(dest, exist_ok=True)
    with zipfile.ZipFile(io.BufferedReader(RemoteFile(URL), BLOCK)) as tpz:
        for name in MEMBERS:
            out = os.path.join(dest, os.path.basename(name))
            with tpz.open(name) as src, open(out + ".part", "wb") as dst:
                while chunk := src.read(BLOCK):
                    dst.write(chunk)
            os.replace(out + ".part", out)
            print(f"ok   {out} ({os.path.getsize(out) // 1024} KiB)")


if __name__ == "__main__":
    main()

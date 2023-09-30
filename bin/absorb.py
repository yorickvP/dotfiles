#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 python3.pkgs.requests -I nixpkgs=channel:nixos-22.05
import json, os, sys, hashlib
from pathlib import Path
import shutil
import tempfile
import requests

if len(sys.argv) < 3:
    print(f"Usage: sudo {sys.argv[0]} [dest] [files..]", file=sys.stderr)
    sys.exit(2)

if os.geteuid() != 0:
    print("Please run as root", file=sys.stderr)
    sys.exit(1)

plexmedia = Path("/data/plexmedia")
dest = plexmedia / sys.argv[1]

sections = {
    "movies": 1,
    "series": 2,
    "anime-movies": 3,
    "anime-series": 4,
    "talks": 5
}

if not dest.is_dir():
    print(f"Error: {dest} is not a directory/does not exist")
    sys.exit(1)

sid = sections[sys.argv[1]]

def hashfile(path: Path) -> str:
    hash = hashlib.sha256()
    buf = bytearray(128 * 1024) # 128kb
    mv = memoryview(buf)
    with path.open('rb') as f:
        while n := f.readinto(mv):
            hash.update(mv[:n])
    return hash.hexdigest()

def symlink_force(name: Path, target: Path) -> None:
    try:
        name.symlink_to(target)
    except FileExistsError:
        tmp = Path(tempfile.mktemp(dir=name.parent))
        tmp.symlink_to(target)
        tmp.replace(name)

def ca_import(source: Path) -> Path:
    if not sourcepath.is_file() or sourcepath.is_symlink():
        print(f"{sourcepath} is not a regular file")
        if sourcepath.is_symlink():
            rsv = sourcepath.resolve()
            if rsv.parent == plexmedia / "ca":
                return rsv
            else:
                sys.exit(2)
        return
    # CA import
    print(f"[{source.name}] hash")
    hash = hashfile(sourcepath)
    print(hash)
    ca_dest = (plexmedia / "ca" / hash).with_suffix(sourcepath.suffix)
    print(f"[{source.name}] copy")
    if ca_dest.exists():
        print(f"warning: skipping copy, already in store")
    else:
        tmp_path = ca_dest.with_suffix(ca_dest.suffix + ".tmp")
        tmp_path.unlink(missing_ok=True)
        try:
            shutil.copyfile(sourcepath, tmp_path)
        except shutil.SameFileError:
            print(f"warning: skipping copy, already in place")
        tmp_path.rename(ca_dest)
    #print(f"chown plex:plex {ca_dest}")
    shutil.chown(ca_dest, user="plex", group="plex")
    return ca_dest

for sourcefile in sys.argv[2:]:
    sourcepath = Path(sourcefile)
    print("CA", sourcepath)
    ca_dest = ca_import(sourcepath)
    # plex import
    destpath = dest / sourcepath.name
    print(f"ln -s {ca_dest} {destpath}")
    symlink_force(destpath, ca_dest)
    shutil.chown(destpath, user="plex", group="plex")
    # torrent link
    symlink_force(sourcepath, ca_dest)


with open("/home/yorick/plex_token", 'r') as f:
    PLEX_TOKEN = f.read().splitlines()[0]

requests.get(f"https://plex.yori.cc/library/sections/{sid}/refresh", headers={
    "X-Plex-Token": PLEX_TOKEN
})

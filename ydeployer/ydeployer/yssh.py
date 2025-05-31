import asyncio
import subprocess
import sys
from subprocess import CalledProcessError
from typing import BinaryIO, overload


async def plumb(a: asyncio.StreamReader):
    while x := await a.read():
        sys.stdout.buffer.write(x)


async def read_collecting(a: asyncio.StreamReader, target: BinaryIO) -> bytes:
    n = []
    while x := await a.read(128):
        n.append(x)
        target.write(x)
        target.flush()
    return b"".join(n)


class SSH:
    child: asyncio.subprocess.Process | None

    def __init__(self, host: str):
        self.host = host
        self.child = None

    async def check(self) -> bool:
        p = await asyncio.create_subprocess_exec(
            "ssh", self.host, "-O", "check", stderr=subprocess.DEVNULL
        )
        return await p.wait() != 255

    def interactive(self):
        print(f"$ ssh {self.host}")
        subprocess.run(["ssh", self.host], check=False) # noqa: S603, S607

    @overload
    async def exec(self, cmd: str, encoding: None) -> bytes: ...
    @overload
    async def exec(self, cmd: str, encoding: str) -> str: ...
    async def exec(self, cmd: str, encoding: None | str = None) -> str | bytes:
        print(f"[{self.host}] $", cmd)
        proc = await asyncio.create_subprocess_exec(
            "ssh",
            self.host,
            "bash",
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if not proc.stdin or not proc.stderr or not proc.stdout:
            raise RuntimeError("something went wrong setting up the pipes")

        async def feed_stdin(stdin: asyncio.StreamWriter):
            stdin.write((cmd + "; exit $?\n").encode("utf-8"))
            await stdin.drain()
            stdin.close()

        _, stdout_data, returncode = await asyncio.gather(
            feed_stdin(proc.stdin),
            read_collecting(proc.stdout, sys.stdout.buffer),
            proc.wait(),
        )
        if returncode != 0:
            raise CalledProcessError(returncode=returncode, cmd=cmd)
        if encoding:
            return stdout_data.decode(encoding).strip()
        else:
            return stdout_data

    async def spawn_child(self):
        self.child = await asyncio.create_subprocess_exec(
            "ssh",
            self.host,
            "-M",
            "-N",
            "-o",
            "Compression=no",
            "-o",
            "PermitLocalCommand=yes",
            "-o",
            "LocalCommand=echo connected",
            stdout=asyncio.subprocess.PIPE,
        )
        if not self.child.stdout:
            raise RuntimeError("child didn't have stdout")
        print(f"[{self.host}] spawned ssh control master")
        data = await self.child.stdout.readline()
        if data != b"connected\n":
            raise RuntimeError("got weird data from ssh:", data.decode("utf8"))
        self.forwarder_task = asyncio.create_task(plumb(self.child.stdout))

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

    def __del__(self):
        if self.child and not self.child.returncode:
            self.child.terminate()
            self.child = None

    @overload
    async def __call__(self, cmd: str, encoding: str = ...) -> str: ...
    @overload
    async def __call__(self, cmd: str, encoding: None = ...) -> bytes:
        pass

    async def __call__(self, cmd: str, encoding: str | None = None) -> str | bytes:
        return await self.exec(cmd, encoding)


async def ssh(target: str) -> SSH:
    ret = SSH(target)
    if await ret.check():
        print(f"[{target}] ssh control master already up")
    else:
        await ret.spawn_child()
    return ret

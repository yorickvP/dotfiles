import asyncio
from subprocess import DEVNULL, PIPE, CalledProcessError
from typing import overload


@overload
async def run(*args, encoding: str, stdout: None | int = ...) -> str: ...


@overload
async def run(*args, encoding: None = None, stdout: None | int = ...) -> bytes: ...


async def run(
    *args: str,
    encoding: str | None = None,
    stdout: None | int = PIPE,
) -> bytes | str | None:
    print("$", *args)
    proc = await asyncio.create_subprocess_exec(
        *args,
        stdout=PIPE,
        stderr=None,
        stdin=DEVNULL,
    )
    stdout_data, stderr_data = await proc.communicate()
    if proc.returncode is None:
        raise RuntimeError("process didn't exit")
    if proc.returncode != 0:
        raise CalledProcessError(returncode=proc.returncode, cmd=args)
    if stdout is not asyncio.subprocess.PIPE:
        return None
    if encoding:
        return stdout_data.decode(encoding).strip()
    else:
        return stdout_data

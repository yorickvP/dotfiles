import asyncio
import os
from collections import defaultdict
import functools
from pydantic import BaseModel, TypeAdapter
from typing import Any, Callable, Concatenate, Coroutine, Literal, TypeAlias
import tempfile

from .yssh import SSH
from .yrun import run

DrvPath: TypeAlias = str
OutPath: TypeAlias = str
NixPath: TypeAlias = DrvPath | OutPath


class OutputType(BaseModel):
    path: OutPath


class InputDrv(BaseModel):
    dynamicOutputs: dict[str, "InputDrv"]
    outputs: list[str]


class ShownDerivation(BaseModel):
    args: list[str]
    builder: str
    env: dict[str, str]
    inputDrvs: dict[DrvPath, InputDrv | list[str]]
    inputSrcs: list[OutPath]
    outputs: dict[str, OutputType]
    system: Literal["x86_64-linux"]


ShowDerivationOutput: TypeAlias = dict[DrvPath, ShownDerivation]


class BuildOutput(BaseModel):
    drvPath: DrvPath
    outputs: dict[str, OutPath]
    startTime: int | None = None
    stopTime: int | None = None


class Expression:
    def __init__(self, expr: str):
        self.expr = expr

    async def derive(self) -> "Derivation":
        drvs = await nixDerive(self.expr)
        drvPath = drvs.drvPath
        drv = await nixShowDerivation(drvPath)
        return Derivation(drvPath, drv[drvPath])

    async def build(self) -> dict[str, "BuiltOutput"]:
        outputs = await nixBuild(self.expr)
        drvMetaJson = await nixShowDerivation(outputs.drvPath)
        [drvPath, drvMeta] = list(drvMetaJson.items())[0]
        drv = Derivation(drvPath, drvMeta)
        return {k: BuiltOutput(v, drv) for k, v in outputs.outputs.items()}


class Derivation:
    def __init__(self, path: str, meta: ShownDerivation):
        self.path = path
        self.meta = meta

    def __repr__(self) -> str:
        return f"«derivation {self.path}»"

    def __str__(self) -> str:
        return repr(self)

    async def build(self) -> dict[str, "BuiltOutput"]:
        outputs = await nixBuild(self.path + "^*")
        return {k: BuiltOutput(v, self) for k, v in outputs.outputs.items()}


class BuiltOutput:
    def __init__(self, path: str, drv: Derivation):
        self.path = path
        self.drv = drv

    async def copy(self, target: SSH):
        await nixCopy(self.path, target)

    def __repr__(self):
        return str(self)

    def __str__(self):
        return self.path


def dedupe[X, Y, **P](
    outer: Callable[Concatenate[list[X], P], Coroutine[Any, Any, list[Y]]],
) -> Callable[Concatenate[X, P], Coroutine[Any, Any, Y]]:
    scheduled: dict[tuple, asyncio.Task[list[Y]]] = {}
    queue: dict[tuple, list[X]] = defaultdict(list)

    async def task(*args, **kwargs) -> list[Y]:
        key = (args, frozenset(kwargs.items()))
        del scheduled[key]
        q = queue.pop(key)
        return await outer(q, *args, **kwargs)

    @functools.wraps(outer)
    async def inner(n: X, *args: P.args, **kwargs: P.kwargs) -> Y:
        key = (args, frozenset(kwargs.items()))
        i = len(queue[key])
        queue[key].append(n)
        if key not in scheduled or scheduled[key].done():
            scheduled[key] = asyncio.create_task(task(*args, **kwargs))
        return (await scheduled[key])[i]

    return inner


temp_dirs = []


# todo keep going
@dedupe
async def nixBuild(attr: list[str]) -> list[BuildOutput]:
    tdir = tempfile.TemporaryDirectory()
    temp_dirs.append(tdir)
    stdout = await run("nom", "build", "--json", "-o", f"{tdir.name}/result", *attr)
    return TypeAdapter(list[BuildOutput]).validate_json(stdout)


@dedupe
async def nixDerive(attr: list[str]) -> list[BuildOutput]:
    stdout = await run("nom", "build", "--json", "--dry-run", *attr)
    return TypeAdapter(list[BuildOutput]).validate_json(stdout)


async def nixShowDerivation(path: NixPath) -> ShowDerivationOutput:
    stdout = await run("nix", "derivation", "show", path + "^*")
    return TypeAdapter(ShowDerivationOutput).validate_json(stdout)


@dedupe
async def nixCopy(attrs: list[str], target: SSH) -> list[None]:
    os.environ["NIX_SSHOPTS"] = "-o compression=no"
    await run("nix", "copy", *attrs, "-s", "--to", f"ssh://{target.host}", stdout=None)
    return [None] * len(attrs)

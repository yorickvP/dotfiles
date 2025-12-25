import socket
from asyncio import gather
from pathlib import Path
from subprocess import CalledProcessError

import fire

from .ynix import Expression
from .yrun import run
from .yssh import SSH, ssh


async def ping(hostname: str) -> bool:
    try:
        await run("ping", "-Anqc3", hostname, stdout=None)
    except CalledProcessError:
        return False
    return True


Home = Expression(".#yorick-home")


class Machine:
    def __init__(
        self, *, name: str, has_home: bool = False, hostname: str | None = None
    ):
        self.name = name
        self.has_home = has_home
        self.hostname = hostname

    @property
    def is_local(self) -> bool:
        return socket.gethostname() == self.name

    @property
    def toplevel(self) -> Expression:
        return Expression(f".#nixosConfigurations.{self.name}.toplevel")

    @property
    def targets(self) -> list[Expression]:
        return [self.toplevel] if not self.has_home else [self.toplevel, Home]

    async def _ssh_target(self) -> str:
        if self.is_local:
            return "localhost"
        if self.hostname and await ping(self.hostname):
            return self.hostname
        return f"{self.name}.home.yori.cc"

    async def ssh(
        self,
        user: str | None = None,
    ) -> SSH:
        host = await self._ssh_target()
        ssh_target = f"{user}@{host}" if user else host
        return await ssh(ssh_target)


machines = {
    "frumar": Machine(name="frumar", hostname="frumar.home.yori.cc"),
    "pennyworth": Machine(name="pennyworth", hostname="pennyworth.yori.cc"),
    "blackadder": Machine(name="blackadder", has_home=True),
    "jarvis": Machine(name="jarvis", has_home=True),
    "smithers": Machine(name="smithers", has_home=True),
    "kirei": Machine(name="kirei", has_home=False),
    "butterscotch": Machine(name="butterscotch", has_home=True),
}


class MachineInterface:
    def __init__(self, machine: Machine):
        self.machine = machine

    async def ssh(self):
        with await self.machine.ssh() as ssh:
            ssh.interactive()

    async def gc(self):
        with await self.machine.ssh("root") as ssh:
            await ssh("nix-collect-garbage -d")

    async def eval(self):
        return await gather(*[t.derive() for t in self.machine.targets])

    async def build(self):
        return await gather(*[t.build() for t in self.machine.targets])

    async def status(self):
        with await self.machine.ssh() as ssh:
            await ssh("systemctl is-system-running")
            await ssh("zpool status -x")
            await ssh("realpath /run/current-system /nix/var/nix/profiles/system")

    async def copy(self):
        builds = [y for x in await self.build() for y in x.values()]
        if not self.machine.is_local:
            with await self.machine.ssh() as ssh:
                await gather(*[x.copy(ssh) for x in builds])
        else:
            print("skipping copy, is localhost")

    async def boot_deploy(self):
        path = (await self.machine.toplevel.build())["out"]
        if not self.machine.is_local:
            with await self.machine.ssh() as ssh:
                await path.copy(ssh)
        # TODO: machine.activate("boot")
        with await self.machine.ssh("root") as ssh:
            await ssh(f"nix-env -p /nix/var/nix/profiles/system --set {path.path}")
            await ssh(f"{path.path}/bin/switch-to-configuration boot")

    async def switch(self):
        path = (await self.machine.toplevel.build())["out"]
        if not self.machine.is_local:
            with await self.machine.ssh() as ssh:
                await path.copy(await self.machine.ssh())
        new_kernel = str((Path(path.path) / "kernel").readlink())
        with await self.machine.ssh("root") as ssh:
            old_kernel = await ssh(
                "readlink /run/booted-system/kernel", encoding="utf-8"
            )
            if new_kernel != old_kernel:
                print(f"[{self.machine.name}] requires reboot because of kernel update")
                return
            await ssh(f"nix-env -p /nix/var/nix/profiles/system --set {path.path}")
            await ssh(f"{path.path}/bin/switch-to-configuration switch")

    def __call__(self, hostname=None):
        if hostname:
            self.machine.hostname = hostname
        return self


class MachineInterfaceHome(MachineInterface):
    async def update_home(self):
        new_path = (await Home.build())["out"]
        if not self.machine.is_local:
            with await self.machine.ssh() as ssh:
                await new_path.copy(ssh)
                await ssh(f"{new_path.path}/activate")
        else:
            await run(f"{new_path.path}/activate")


interfaces = {
    k: MachineInterfaceHome(v) if v.has_home else MachineInterface(v)
    for k, v in machines.items()
}


def main():
    fire.Fire(
        {
            "home": Home,
            **interfaces,
        }
    )


if __name__ == "__main__":
    main()

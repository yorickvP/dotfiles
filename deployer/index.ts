import { ssh, SSH } from './ssh.js'
import { Expression, BuiltOutput } from './nix.js'

class Cmd {
  registry: Record<string, () => Promise<void>> = {};
  register(obj: string, action: string, fn: () => Promise<void>) {
    this.registry[`${obj}.${action}`] = fn
  }
  registerAll(obj: string, intf: Object & { _commands?: string[] }) {
    if (!intf._commands) return
    const proto = Object.getPrototypeOf(intf)
    for (const name of intf._commands) {
      if (name != "constructor" && typeof proto[name] === "function") {
        this.register(obj, name, proto[name].bind(intf))
      }
    }
  }
  async run() {
    const opt = argv._[0]
    if (opt == "__autocompletes") {
      for (const k of Object.keys(this.registry)) {
        console.log(k)
      }
      return
    }
    if (opt && this.registry[opt]) await this.registry[opt]()
        else {
          console.log("Possible options: \n")
          for (const k of Object.keys(this.registry)) {
            console.log("-", k)
          }
        }
  }
}

const action = new Cmd()

async function ping(hostname: string) {
  return await $`ping -Anqc3 ${hostname}`.exitCode == 0
}

class Machine {
  name: string;
  hasHome: boolean = false;
  hostname?: string;
  constructor(args: {name?: string, hasHome?: boolean, hostname?: string}) {
    Object.assign(this, args)
    // todo
    this.name = ""
  }
  isLocal() {
    return os.hostname() == this.name
  }
  get attr(): Expression {
    return new Expression(`.#nixosConfigurations.${this.name}.toplevel`)
  }
  private async sshTarget() {
    if (this.isLocal()) return "localhost"
    if (this.hostname && await ping(this.hostname)) {
      return this.hostname
    } else {
      // todo: directify
      return `${this.name}.vpn.yori.cc`
    }
  }
  async findIP(): Promise<typeof Machine.prototype.ssh> {
    const host = await this.sshTarget()
    return <R>(user?: string, cb?: () => Promise<R>): Promise<SSH|R> => {
      const sshTarget = user ? `${user}@${host}` : host
      if (cb !== undefined) return ssh(sshTarget, cb)
      return ssh(sshTarget)
    }
  }

  ssh(user?: string): Promise<SSH>
  ssh<R>(user?: string, cb?: () => Promise<R>): Promise<R>
  async ssh<R>(user?: string, cb?: () => Promise<R>) {
    return (await this.findIP())(user, cb)
  }
  get targets() {
    if (this.hasHome) return [this.attr, Home]
    else return [this.attr]
  }
}

const machines = {
  frumar: new Machine({hostname: "frumar.home.yori.cc"}),
  pennyworth: new Machine({hostname: "pennyworth.yori.cc"}),
  blackadder: new Machine({hasHome: true}),
  jarvis: new Machine({hasHome: true}),
  smithers: new Machine({hasHome: true}),
}
for (const [name, machine] of Object.entries(machines))
    machine.name = name

function cmd<R>(target: { _commands?: string[] }, propertyKey: string, descriptor: PropertyDescriptor): void {
  if (target._commands == undefined) target._commands = []
  target._commands.push(propertyKey)
}

class MachineInterface {
  machine: Machine
  _commands?: string[]
  constructor(machine: Machine) {
    this.machine = machine
    // hack:
    delete this._commands
  }
  @cmd
  async ssh() {
    (await this.machine.ssh()).interactive()
  }
  @cmd
  gc() {
    return this.machine.ssh("root", () => $`nix-collect-garbage -d`)
  }
  @cmd
  eval() {
    return Promise.all(this.machine.targets.map(x => x.derive()))
  }
  @cmd
  build() {
    return Promise.all(this.machine.targets.map(x => x.build()))
  }
  @cmd
  status() {
    return this.machine.ssh(undefined, async () => {
      await $`systemctl is-system-running`
      await $`zpool status -x`
      await $`realpath /run/current-system /nix/var/nix/profiles/system`
    })
  }

  @cmd
  async copy() {
    const machineSSH = await this.machine.findIP()
    const outputs = (await Promise.all(this.machine.targets.map(x => x.build().then(Object.values)))).flat()
    if (this.machine.isLocal()) {
      console.log("skipping copy, is localhost")
      return
    }
    const conn = await machineSSH()
    await Promise.all(Object.values(outputs).map(x => x.copy(conn)))
    // machine.toplevel.buildAndCopy(machine.ssh)
    // Home.buildAndCopy(machine.ssh)
  }
  @cmd
  async "boot-deploy"() {
    const machineSSH = await this.machine.findIP()
    const path = (await this.machine.attr.build()).out
    if (!this.machine.isLocal()) {
      const conn = await machineSSH()
      await path.copy(conn)
    }
    // machine.toplevel.buildAndCopy(machine.ssh)
    // machine.ssh.within(machine.toplevel.activate("boot"))
    await machineSSH("root", async () => {
      await $`nix-env -p /nix/var/nix/profiles/system --set ${path.path}`
      await $`${path}/bin/switch-to-configuration boot`
    })
  }
  @cmd
  async "switch"() {
    const machineSSH = await this.machine.findIP()
    const path = (await this.machine.attr.build()).out
    if (!this.machine.isLocal()) {
      const conn = await machineSSH()
      await path.copy(conn)
    }
    const new_kernel = (await $`readlink ${path.path}/kernel`).stdout
    await machineSSH("root", async () => {
      const old_kernel = (await $`readlink /run/booted-system/kernel`).stdout
      if (new_kernel !== old_kernel) {
        console.error(`[${this.machine.name}] requires reboot because of kernel update`)
        process.exit(1)
      }
      await $`nix-env -p /nix/var/nix/profiles/system --set ${path.path}`
      await $`${path.path}/bin/switch-to-configuration switch`
    })
  }
}

class MachineInterfaceHome extends MachineInterface {
  @cmd
  async "update-home"() {
    const new_path = (await Home.build()).out
    if (this.machine.isLocal()) {
      await $`${new_path.path}/activate`
    } else {
      const conn = await this.machine.ssh()
      await new_path.copy(conn)
      await conn.within(() => $`${new_path.path}/activate`)
    }
  }
}


for (const machine of Object.values(machines)) {
  action.registerAll(machine.name, machine.hasHome ? new MachineInterfaceHome(machine) : new MachineInterface(machine))
}

action.register("all", "build", async () => {
  console.log(await (new Expression(".#")).build())
})

const Home = new Expression(".#yorick-home")

action.register("home", "build", async () => {
  console.log(await Home.build())
})

action.register("home", "eval", async () => {
  console.log(await Home.derive())
})

action.register("local", "boot-deploy", async () => {
  await action.registry[`${os.hostname()}.boot-deploy`]()
})

action.register("local", "status", async () => {
  await action.registry[`${os.hostname()}.status`]()
})

await action.run()

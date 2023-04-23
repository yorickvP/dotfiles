
import 'zx/globals';
import { retry } from 'zx/experimental'

import { spawn, SpawnOptions, ChildProcess } from 'child_process'
import { Socket } from 'node:net'

export function ssh(host: string): Promise<SSH>
export function ssh<R>(host: string, cb: () => Promise<R>): Promise<R>
export async function ssh<R>(host: string, cb?: () => Promise<R>) {
  const ret = new SSH(host)
  try {
    await ($`ssh ${host} -O check`).quiet()
  } catch (p) {
    if (p instanceof ProcessOutput && p.exitCode == 255) {
      console.log("Spawning ssh master")
      let x = $`ssh ${host} -M -N -o compression=no`
      await sleep(1000)
      await retry(20, '1s', () => $`ssh ${host} -O check`.quiet())
      console.log("SSH connected")
      if (x.child) {
        x.child.unref()
        if (x.child.stderr instanceof Socket) x.child.stderr.unref()
        if (x.child.stdout instanceof Socket) x.child.stdout.unref()
        ret.child = x.child
        process.on('beforeExit', () => {
          ret.stop()
        })
      } else {
        console.warn("Failed to spawn SSH master, but someone else did")
      }
    } else {
      throw p
    }
  }
  if (cb !== undefined) return ret.within(cb)
    else return ret
}

export class SSH {
  child?: ChildProcess | null;
  constructor(public host: string) { }
  within<R>(cb: () => Promise<R>): Promise<R> {
    return within(async () => {
      $.spawn = (command: string, options: any): any => {
        const stdio = ["pipe", options.stdio[1], options.stdio[2]]
        const proc: ChildProcess = spawn("ssh", [this.host, options.shell],
          Object.assign({}, options, {shell: false, stdio}))
        // todo: type safety
        if (!proc.stdin) throw new Error("Failed to spawn input pipe")
        proc.stdin.write(command + "; exit $?\n")
        if (options.stdio[0] == 'inherit') process.stdin.pipe(proc.stdin)
        return proc
      }
      $.log = (entry) => {
        switch(entry.kind) {
                case 'cmd':
                    if (entry.verbose) process.stderr.write(`[${this.host}] `)
                    break;
        }
        log(entry)
      }
      return cb()
    })
  }
  interactive() {
    $`ssh ${this.host}`
  }
  stop() {
    if (this.child) {
      $`ssh ${this.host} -O stop`
      this.child = null
    }
  }
}


import 'zx/globals';

import { spawn, ChildProcess } from 'child_process'
import { Socket } from 'node:net'

async function promiseWithTimeout<T>(timeoutMs: number, promise: Promise<T>, failureMessage?: string) { 
  let timeoutHandle: NodeJS.Timeout | null = null
  const timeoutPromise = new Promise<never>((_resolve, reject) => {
    timeoutHandle = setTimeout(() => reject(new Error(failureMessage)), timeoutMs)
  })
  const result = await Promise.race([promise, timeoutPromise])
  if (timeoutHandle) clearTimeout(timeoutHandle)
  return result
}

const to_kill: ProcessPromise[] = []

// sad that I can't chain these
process.on("uncaughtException", err => {
  console.error("uncaught exception", err)
  console.log("killing", to_kill.length, "child processes")
  for (const k of to_kill) if (k.child?.pid) process.kill(k.child.pid)
  to_kill.length = 0
  process.exit(1)
})

export function ssh(host: string): Promise<SSH>
export function ssh<R>(host: string, cb: () => Promise<R>): Promise<R>
export async function ssh<R>(host: string, cb?: () => Promise<R>) {
  const ret = new SSH(host)
  try {
    await ($`ssh ${host} -O check`).quiet()
  } catch (p) {
    if (p instanceof ProcessOutput && p.exitCode == 255) {
      console.log("Spawning ssh master")
      const x = $`ssh ${host} -M -N -o Compression=no -o PermitLocalCommand=yes -o LocalCommand="echo connected"`
      to_kill.push(x)
      await promiseWithTimeout(60000, new Promise<void>((resolve, _reject) => {
        x.stdout.on('data', (d: Buffer) => {
          if (d.toString('utf8').trim() == "connected")
            resolve()
        })
      }))
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
      // todo: the default options.shell is set to local which.sync('bash')
      // which doesn't neccesarily work on the remote
      $.shell = "bash"
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

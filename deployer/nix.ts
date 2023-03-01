import 'zx/globals';
import { SSH } from './ssh.js'

type DrvPath = string
type OutPath = string
type NixPath = DrvPath | OutPath

type ShownDerivation = {
  args: Array<string>,
  builder: string,
  env: Record<string, string>,
  inputDrvs: Record<DrvPath, string[]>,
  inputSrcs: Array<OutPath>,
  outputs: Record<string, { path: OutPath }>,
  system: "x86-64_linux"
};
type ShowDerivationOutput = Record<DrvPath, ShownDerivation>

type OutputSpec<R> = { out: R } & Record<string, R>

type BuildOutput = {
  drvPath: DrvPath,
  outputs: OutputSpec<OutPath>,
  startTime?: number,
  stopTime?: number
}

export class Expression {
  expr: string
  constructor(expr: string) {
    this.expr = expr
  }
  async derive(): Promise<Derivation> {
    const {drvPath} = await nix.derive(this.expr)
    const drv = await nix.showDerivation(drvPath)
    return new Derivation(drvPath, drv[drvPath])
  }
  async build(): Promise<OutputSpec<BuiltOutput>> {
    const outputs = await nix.build(this.expr)
    const drvMetaJson = await nix.showDerivation(outputs.drvPath)
    const [drvPath, drvMeta] = Object.entries(drvMetaJson)[0]
    const drv = new Derivation(drvPath, drvMeta)
    const ret: Record<string, BuiltOutput> = {}
    for (const [k, v] of Object.entries(outputs.outputs)) {
      ret[k] = new BuiltOutput(v, drv)
    }
    return Object.assign(ret, { out: ret.out })
  }
}
export class Derivation {
  path: string
  //outputs?: Array<BuiltOutput>
  meta: ShownDerivation
  constructor(path: string, meta: ShownDerivation) {
    this.path = path
    this.meta = meta
  }
  async build(): Promise<{out: BuiltOutput} & Array<BuiltOutput>> {
    const outputs: BuildOutput = await nix.build(this.path)
    const ret = Object.values(outputs.outputs).map(x => new BuiltOutput(x, this))
    return Object.assign(ret, { out: new BuiltOutput(this.meta.outputs.out.path, this) })
  }
}
export class BuiltOutput {
  path: string
  drv: Derivation
  constructor(path: string, drv: Derivation) {
    this.path = path
    this.drv = drv
  }
  async copy(target: SSH): Promise<void> {
    return nix.copy(this.path, target)
  }
}

function dedupe<A, B, Rest extends any[]>(fn: (xs: A[], ...rest: Rest) => Promise<B[]>):
{ (x: A, ...rest: Rest): Promise<B>; (x: A[], ...rest: Rest): Promise<B[]>; } {
  type QueueEntry = {
    x: A,
    resolve: (res: B) => void,
    reject: (err: any) => void
  }
  const queues = new Map<string, QueueEntry[]>()
  function inner(x: A, ...rest: Rest): Promise<B>
  function inner(x: A[], ...rest: Rest): Promise<B[]>
  function inner(x: A | A[], ...rest: Rest) {
    // todo: also dedupe array results
    if (Array.isArray(x)) return fn(x, ...rest)
    // map queue by rest
    const stringified = JSON.stringify(rest)
    const had = queues.has(stringified)
    const queue = queues.get(stringified) || []
    const ret = new Promise<B>((resolve, reject) => {
      queue.push({x, resolve, reject})
    })
    if (!had) {
      queues.set(stringified, queue)
      setImmediate(() => {
        queues.delete(stringified)
        fn(queue.map(({x}) => x), ...rest)
          .then(results => {
            for (const [i, {resolve}] of queue.entries()) resolve(results[i])
          })
          .catch(e => {
            for (const {reject} of queue) reject(e)
          })
      })
    }
    return ret
  }
  return inner
}

//function nixBuild(attr: string[]): Promise<BuildOutput[]>
//function nixBuild(attr: string): Promise<BuildOutput>
async function nixBuild(attr: string[]): Promise<BuildOutput[]> {
  const tmp = (await $`mktemp -d`).stdout.trim()
  process.on('exit', () => fs.removeSync(tmp))
  const ret = JSON.parse((await $`nom build --json ${attr} -o ${tmp}/result`).stdout)
  if (Array.isArray(attr)) return ret
  return ret[0]
}

namespace nix {
  export const build = dedupe(nixBuild)
  export async function showDerivation(path: NixPath): Promise<ShowDerivationOutput> {
    return JSON.parse((await $`nix show-derivation ${path}`.quiet()).stdout)
  }
  export const derive = dedupe(async (attr: string[]): Promise<BuildOutput[]> => {
    return JSON.parse((await $`nom build --json --dry-run ${attr}`).stdout)
  })
  export const copy = dedupe(async (attrs: string[], target: SSH): Promise<void[]> => {
    process.env.NIX_SSHOPTS = "-o compression=no";
    await $`nix copy ${attrs} --to ssh://${target.host}`
    return Array(attrs.length)
  })
}

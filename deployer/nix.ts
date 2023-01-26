import 'zx/globals';
import { SSH } from './ssh.js'

type DrvPath = string
type OutPath = string
type NixPath = DrvPath | OutPath

type ShownDerivation = {
  args: Array<string>,
  builder: string,
  env: { [index: string]: string } ,
  inputDrvs: { [index: DrvPath]: Array<String> },
  inputSrcs: Array<OutPath>,
  outputs: { [index: string]: { path: OutPath }},
  system: "x86-64_linux"
};
type ShowDerivationOutput = {
  [index: DrvPath]: ShownDerivation
}

export class Expression {
  expr: string
  constructor(expr: string) {
    this.expr = expr
  }
  async derive(): Promise<Derivation> {
    const drvPath = await nix.eval(this.expr)
    const drv = await nix.showDerivation(drvPath)
    return new Derivation(drvPath, drv[drvPath])
  }
  async build(): Promise<{out: BuiltOutput} & Array<BuiltOutput>> {
    const outputs = await nix.build(this.expr)
    const drvMetaJson = await nix.showDerivation(outputs[0])
    const [drvPath, drvMeta] = Object.entries(drvMetaJson)[0]
    const drv = new Derivation(drvPath, drvMeta)
    const ret = outputs.map(x => new BuiltOutput(x, drv))
    return Object.assign(ret, { out: new BuiltOutput(drv.meta.outputs.out.path, drv) })
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
    const outputs = await nix.build(this.path)
    const ret = outputs.map(x => new BuiltOutput(x, this))
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

export const nix = {
  async build(attr: string | Array<string>, name="result"): Promise<Array<OutPath>> {
    const tmp = (await $`mktemp -d`).stdout.trim()
    process.on('exit', () => fs.removeSync(tmp))
    await $`nom build ${attr} -o ${tmp}/${name}`
    const files = await fs.readdir(`${tmp}`)
    return Promise.all(files.map(f => fs.readlink(`${tmp}/${f}`)))
  },
  async showDerivation(path: NixPath): Promise<ShowDerivationOutput> {
    return JSON.parse((await $`nix show-derivation ${path}`.quiet()).stdout)
  },
  async eval(attr: string) : Promise<DrvPath> {
    return JSON.parse((await $`nix eval ${attr}.drvPath --json`).stdout)
  },
  async copy(attrs: string | Array<string>, target: SSH): Promise<void> {
    process.env.NIX_SSHOPTS = "-o compression=no";
    await $`nix copy ${attrs} --to ssh://${target.host}`
  }
}

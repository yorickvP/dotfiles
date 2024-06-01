{ flake-inputs, pkgs, python3, runCommand }:
let
  dream2nix = flake-inputs.dream2nix;
  module = { dream2nix, config, lib, ... }: {
    imports = [ dream2nix.modules.dream2nix.pip ];
    name = "llm-env";
    deps.python = python3;
    version = "0.14";
    pip.requirementsList = [
      "llm==0.14"
      "llm-claude-3==0.3"
      "llm-replicate==0.3.1"
      "llm-gemini==0.1a4"
      "llm-cmd==0.1a0"
    ];
    pip.flattenDependencies = true;
    public = config.pip.env;
    paths.projectRoot = ./..;
    paths.package = "pkgs/llm";
  };
  packages = dream2nix.lib.evalModules {
    packageSets.nixpkgs = pkgs;
    modules = [ module ];
  };

  pyEnv = packages.config.public.pyEnv;
in
runCommand "llm" {} ''
  mkdir -p $out/bin
  cp ${pyEnv}/bin/llm $_
''

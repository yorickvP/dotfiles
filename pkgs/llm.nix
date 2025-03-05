{ flake-inputs, pkgs, python3, runCommand }:
let
  dream2nix = flake-inputs.dream2nix;
  module = { dream2nix, config, lib, ... }: {
    imports = [ dream2nix.modules.dream2nix.pip ];
    name = "llm-env";
    deps.python = python3;
    version = "0.23";
    pip.requirementsList = [
      "llm==0.23"
      "llm-anthropic==0.15.1"
      "llm-gemini==0.13.1"
      "llm-cmd==0.2a0"
      "llm-jq==0.1.1"
      "llm-whisper-api==0.1.1"
      "llm-deepseek==0.1.4"
      "llm-fireworks==0.1a0"
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

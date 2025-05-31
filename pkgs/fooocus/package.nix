{
  dream2nix,
  config,
  lib,
  ...
}:
{
  imports = [ dream2nix.modules.dream2nix.pip ];

  name = "Fooocus";
  version = "2.4.3";

  mkDerivation = {
    src = config.deps.fetchFromGitHub {
      owner = "lllyasviel";
      repo = config.name;
      rev = "v${config.version}";
      hash = "sha256-+vf/uggcO8FeCuGLrgovRSae/Rka1Y2u69qttImtMdY=";
    };
    nativeBuildInputs = [ config.deps.which ];
    buildPhase = "true";
    installPhase = ''
      mkdir $out
      cp -r ./* $out
      ln -s /tmp/fooocus $out/input
      ln -s /var/lib/fooocus/auth.json $out/auth.json
      ln -s /var/lib/fooocus/sorted_styles.json $out/sorted_styles.json
      for f in $out/{launch,webui}.py; do
        chmod +x $f
        sed -i '1s;^;#!/usr/bin/env python\n;' $f
        # wrapProgram $f --set PYTHONPATH "$PYTHONPATH:$out/backend/headless"
      done
      makeWrapper $(which python) $out/bin/fooocus \
        --add-flags $out/launch.py \
        --set PYTHONPATH "$PYTHONPATH:$out/backend/headless"
    '';
  };
  buildPythonPackage.format = "other";

  deps =
    { nixpkgs, ... }:
    {
      inherit (nixpkgs) fetchFromGitHub which;
      inherit (nixpkgs.cudaPackages_12_1) cudatoolkit cudnn;
    };
  pip = {
    drvs = {
      torch.env.appendRunpaths = [
        "/run/opengl-driver/lib"
        "$ORIGIN"
      ];
      # libnvToolsExt.so
      torch.mkDerivation.buildInputs = [ config.deps.cudatoolkit ];
      # libcudart.so.12
      torchvision.mkDerivation.buildInputs = [ config.deps.cudatoolkit.lib ];
      # libcudart.so.12
      xformers.mkDerivation.buildInputs = [ config.deps.cudatoolkit.lib ];
    };
    pypiSnapshotDate = "2024-06-10";
    flattenDependencies = true;
    buildDependencies.setuptools = false;

    requirementsList = [
      "torchsde==0.2.5"
      "einops==0.4.1"
      "transformers==4.30.2"
      "safetensors==0.3.1"
      "accelerate==0.21.0"
      "pyyaml==6.0"
      "Pillow==9.2.0"
      "scipy==1.9.3"
      "tqdm==4.64.1"
      "psutil==5.9.5"
      "numpy==1.23.5"
      "pytorch_lightning==1.9.4"
      "omegaconf==2.2.3"
      "gradio==3.41.2"
      "pygit2==1.12.2"
      "opencv-contrib-python==4.8.0.74"
      "torch==2.1.1+cu121"
      "torchvision==0.16.1"
      "xformers==0.0.23"
      "triton"
      "setuptools"
      "httpx==0.24.1"
      "--extra-index-url"
      "https://download.pytorch.org/whl/cu121"
    ];
  };
}

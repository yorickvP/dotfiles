{ dream2nix, config, lib, ... }: {
  imports = [ dream2nix.modules.dream2nix.pip ];

  name = "Fooocus";
  version = "2.1.807";

  mkDerivation = {
    src = config.deps.fetchFromGitHub {
      owner = "yorickvP";
      repo = config.name;
      rev = "cc11a770ea8db7573ae58b9b8fc30edabaa4a146";
      hash = "sha256-9DV9r1GG3vVwsx+0KYXL3Sd8g5qjSShbBWa1j74BnUs=";
    };
    buildPhase = "true";
    installPhase = ''
      mkdir $out
      cp -r ./* $out
      ln -s /tmp/fooocus $out/input
      for f in $out/{launch,webui}.py; do
        chmod +x $f
        sed -i '1s;^;#!/usr/bin/env python\n;' $f
        wrapProgram $f --set PYTHONPATH "$PYTHONPATH:$out/backend/headless"
      done
    '';
  };
  buildPythonPackage.format = "other";

  deps = { nixpkgs, ... }: {
    inherit (nixpkgs) fetchFromGitHub;
    inherit (nixpkgs.cudaPackages_12_1) cudatoolkit cudnn;
  };
  pip = {
    drvs = {
      torch.env.appendRunpaths = [ "/run/opengl-driver/lib" "$ORIGIN" ];
      # libnvToolsExt.so
      torch.mkDerivation.buildInputs = [ config.deps.cudatoolkit ];
      # libcudart.so.12
      torchvision.mkDerivation.buildInputs = [ config.deps.cudatoolkit.lib ];
      # libcudart.so.12
      xformers.mkDerivation.buildInputs = [ config.deps.cudatoolkit.lib ];
    };
    pypiSnapshotDate = "2023-10-29";
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
      "torch==2.1.0+cu121"
      "torchvision==0.16.0"
      "xformers>=0.0.20"
      "triton"
      "setuptools"
      "httpx==0.24.1"
      "--extra-index-url" "https://download.pytorch.org/whl/cu121"
    ];
  };
}

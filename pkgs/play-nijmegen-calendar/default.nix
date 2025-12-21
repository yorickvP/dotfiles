{
  lib,
  python3,
  callPackage,
  callPackages,
  flake-inputs,
}:

let
  inherit (flake-inputs) uv2nix pyproject-nix pyproject-build-systems;

  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (callPackage pyproject-nix.build.packages {
      python = python3;
    }).overrideScope
      (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          overlay
        ]
      );
  inherit (callPackages pyproject-nix.build.util { }) mkApplication;

in
mkApplication {
  venv = pythonSet.mkVirtualEnv "play-nijmegen-calendar-env" workspace.deps.default;
  package = pythonSet.play-nijmegen-calendar;
}

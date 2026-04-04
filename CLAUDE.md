# Creating a PR

You can create a PR by pushing to a branch and using `fj pr create --base main --head <branch> --body "..." [title]`.

# Repo layout

This is a nix flake, so don't forget to `git add` new files.

- nixos: contains the nixos modules and machine definitions.
- pkgs:
  - pkgs/*/default.nix is automatically callPackage'd by pkgs/default.nix and exported on the flake packages and in the overlay.
  - patches are added manually in pkgs/default.nix.
- bin: loose scripts, added manually in bin/default.nix

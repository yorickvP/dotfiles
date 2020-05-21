let
  lib = import <nixpkgs/lib>;
  n = url: conf: let
    c = import "${url}/nixos/lib/eval-config.nix" {
      modules = [ ./roles conf ];
      extraArgs.name = lib.removeSuffix ".nix" (builtins.baseNameOf conf);
      extraArgs.nixpkgs = url;
    };
  in c.config.system.build // c;
  git = n "https://github.com/NixOS/nixpkgs/archive/master.tar.gz";
  stable = n (builtins.fetchTarball "channel:nixos-20.03");
  unstable = n (builtins.fetchTarball "channel:nixos-unstable-small");
  checkout = n ../projects/nixpkgs;
  channel = n "/nix/var/nix/profiles/per-user/root/channels/nixos";
in
{
  pennyworth = (unstable ./logical/pennyworth.nix).toplevel;
  jarvis     = (channel ./logical/jarvis.nix).toplevel;
  blackadder = (channel ./logical/blackadder.nix).toplevel;
  ascanius   = (channel ./logical/ascanius.nix).toplevel;
  woodhouse  = (channel ./logical/woodhouse.nix).toplevel; # 192.168.178.39
  frumar     = (channel ./logical/frumar.nix).toplevel; # frumar.local
  zazu       = (stable ./logical/zazu.nix).toplevel;
}

{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.yscripts.backup-laptop ];
}

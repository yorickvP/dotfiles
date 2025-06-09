let
  yorick = "age16t7splw64xc6qc7eannw2ahpxace763uu93sqr5d3l4uuy8hze0qcvu2j2";
  blackadder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+7qAXkZdW706X2/+cqKOmvSHsRDueUfAVWcrFaL+64";
  pennyworth = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgc/m2WkhnMRB1ohM5TmMGmdY3qja4iarqFBEPgZVTO";
  frumar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3ljgcmFgfcZA2UP4Mah4lMVKTtXkDurwsj9gAzn8fA";
  smithers = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWdp+DQk3P1JioWlwyEHE0Htri9tz5OMwJf9d8xnAgE";
  jarvis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKd8oRn7T+NnzDbTLaWyiUGIRZ21n42zdozkuUoHp8IX";
  kirei = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPE2ctlrLLIR78hJ5/TQi6K6/+GckHAdjUwVfAnTuNIL";
in
builtins.mapAttrs
  (x: y: {
    publicKeys = [ yorick ] ++ y;
  })
  {
    "wg.blackadder.age" = [ blackadder ];
    "wg.frumar.age" = [ frumar ];
    "wg.jarvis.age" = [ jarvis ];
    "wg.pennyworth.age" = [ pennyworth ];
    "wg.smithers.age" = [ smithers ];
    "wg.kirei.age" = [ kirei ];
    "wg.mullvad-nl4.age" = [ frumar ];
    "grafana.env.age" = [ frumar ];
    "http.muflax.age" = [ pennyworth ];
    "nix-netrc.age" = [
      blackadder
      jarvis
    ];
    "nix-netrc-yorick.age" = [
      blackadder
      pennyworth
      frumar
      smithers
      jarvis
      kirei
    ];
    "pennyworth_borg_repo.age" = [ pennyworth ];
    "pennyworth_borg_ssh.age" = [ pennyworth ];
    "frumar_borg_ssh.age" = [ frumar ];
    "frumar_borg_repo.age" = [ frumar ];
    "yorick-mail-pass.age" = [ pennyworth ];
    "yorick-user-pass.age" = [
      blackadder
      pennyworth
      frumar
      smithers
      jarvis
      kirei
    ];
    "root-user-pass.age" = [
      blackadder
      pennyworth
      frumar
      smithers
      jarvis
    ];
    "kirei-root-user-pass.age" = [ kirei ];
    "frumar-mail-pass-hash.age" = [ pennyworth ];
    "frumar-mail-pass.age" = [ frumar ];
    "kirei-mail-pass-hash.age" = [ pennyworth ];
    "kirei-mail-pass.age" = [ kirei ];
    "zigbee2mqtt.env.age" = [ frumar ];
    "marvin-tracker.env.age" = [ frumar ];
    "oauth2-proxy.age" = [ frumar ];
    "attic.env.age" = [ frumar ];
    "yobot.toml.age" = [ pennyworth ];
    "wg.dk.blackadder.age" = [ blackadder ];
    "wg.dk.smithers.age" = [ smithers ];
    "wg.dk.archbox.conf.age" = [ blackadder ];
    "govee2mqtt.env.age" = [ frumar ];
    "frumar-disk-encryption.age" = [ frumar ];
    "transmission-rpc.age" = [ frumar ];
    "rspamd-env.age" = [ pennyworth ];
    "acme.age" = [
      frumar
      pennyworth
    ];
  }

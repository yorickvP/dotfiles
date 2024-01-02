let
  yorick = "age16t7splw64xc6qc7eannw2ahpxace763uu93sqr5d3l4uuy8hze0qcvu2j2";
  blackadder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+7qAXkZdW706X2/+cqKOmvSHsRDueUfAVWcrFaL+64";
  pennyworth = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgc/m2WkhnMRB1ohM5TmMGmdY3qja4iarqFBEPgZVTO";
  frumar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3ljgcmFgfcZA2UP4Mah4lMVKTtXkDurwsj9gAzn8fA";
  smithers = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWdp+DQk3P1JioWlwyEHE0Htri9tz5OMwJf9d8xnAgE";
  jarvis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKd8oRn7T+NnzDbTLaWyiUGIRZ21n42zdozkuUoHp8IX";

in
{
  "wg.blackadder.age".publicKeys = [ yorick blackadder ];
  "wg.frumar.age".publicKeys = [ yorick frumar ];
  "wg.jarvis.age".publicKeys = [ yorick jarvis ];
  "wg.pennyworth.age".publicKeys = [ yorick pennyworth ];
  "wg.smithers.age".publicKeys = [ yorick smithers ];
  "wg.mullvad-nl4.age".publicKeys = [ yorick frumar ];
  "grafana.env.age".publicKeys = [ yorick frumar ];
  "http.muflax.age".publicKeys = [ yorick pennyworth ];
  "nix-netrc.age".publicKeys = [ yorick blackadder jarvis ];
  "pennyworth_borg_repo.age".publicKeys = [ yorick pennyworth ];
  "pennyworth_borg_ssh.age".publicKeys = [ yorick pennyworth ];
  "transip-key.age".publicKeys = [ yorick frumar ];
  "yorick-mail-pass.age".publicKeys = [ yorick pennyworth ];
  "yorick-user-pass.age".publicKeys = [ yorick blackadder pennyworth frumar smithers jarvis ];
  "root-user-pass.age".publicKeys = [ yorick blackadder pennyworth frumar smithers jarvis ];
  "frumar-mail-pass-hash.age".publicKeys = [ yorick pennyworth ];
  "frumar-mail-pass.age".publicKeys = [ yorick frumar ];
  "zigbee2mqtt.env.age".publicKeys = [ yorick frumar ];
  "oauth2-proxy.age".publicKeys = [ yorick frumar ];
}

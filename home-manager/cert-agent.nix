{ lib, pkgs, ... }:
{
  systemd.user.services.cert-agent = {
    Unit = {
      Description = "SSH certificate agent proxy";
      Requires = [
        "cert-agent.socket"
        "gpg-agent-ssh.socket"
      ];
      # ConditionPathExists = "%h/.ssh/certificates";
    };
    Service = {
      Environment = "SSH_AUTH_SOCK=%t/gnupg/S.gpg-agent.ssh";
      # ExecStart = "${pkgs.cert-agent}/bin/cert-agent %h/.ssh/certificates";
      ExecStart = "${pkgs.cert-agent}/bin/cert-agent ${../ssh-certificates}";
    };
  };
  systemd.user.sockets.cert-agent = {
    Socket = {
      ListenStream = "%t/ssh-agent";
      SocketMode = "0700";
      DirectoryMode = "0700";
    };
    Install.WantedBy = [ "sockets.target" ];
  };
  # Override the SSH_AUTH_SOCK set by services.gpg-agent.enableSshSupport;
  # the forwarded-agent (SSH_CONNECTION) check is built into this option.
  sshAuthSock.initialization = lib.mkForce {
    bash = ''export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent"'';
    fish = "set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent";
    nushell = ''$env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent"'';
  };
}

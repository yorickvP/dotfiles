{
  lib,
  buildEnv,
  dockerTools,
  writeShellScriptBin,
  claude-code,
  bashInteractive,
  coreutils,
  git,
  ripgrep,
  fd,
  jq,
  less,
  gnugrep,
  gnused,
  gawk,
  findutils,
  diffutils,
  hostname,
  gnutar,
  gzip,
  curl,
  lix,
  writeTextDir,
  unzip,
  which,
  xxd,
  ghostty,
  nix-ld,
  zlib,
  libusb1,
  libxcrypt-legacy,
  systemd,
  uv,
  runCommand,
  zstd,
  stdenv,
  openssl,
  attr,
  libssh,
  bzip2,
  libxml2,
  acl,
  libsodium,
  util-linux,
  xz,
  openssh,
  proquint,
  forgejo-cli,
  gh,
}:
let
  uid = "1000";
  gid = "100";
  passwd = writeTextDir "etc/passwd" ''
    root:x:0:0:root:/root:/bin/bash
    nobody:x:65534:65534:nobody:/nonexistent:/bin/false
    claude:x:${uid}:${gid}:claude:/home/claude:/bin/bash
  '';
  group = writeTextDir "etc/group" ''
    root:x:0:
    users:x:100:claude
    nobody:x:65534:
  '';
  nsswitch = writeTextDir "etc/nsswitch.conf" ''
    hosts: files dns
  '';
  nixConf = writeTextDir "etc/nix/nix.conf" ''
    experimental-features = nix-command flakes
  '';
  nix-ld-link = runCommand "nix-ld-link" { } ''
    mkdir -p $out/lib64
    ln -s ${nix-ld}/libexec/nix-ld $out/lib64/ld-linux-x86-64.so.2
  '';
  gitConfig = writeTextDir "etc/gitconfig" (
    lib.generators.toGitINI {
      github.user = "yorickvP";
      init.defaultBranch = "main";
      pull.ff = "only";
      push.autoSetupRemote = true;
      push.default = "simple";
      rebase.autoSquash = true;
      user = {
        email = "yorick@yorickvanpelt.nl";
        name = "Yorick van Pelt";
      };
    }
  );
  nix-ld-lib-path = buildEnv {
    name = "nix-ld-library";
    paths = map lib.getLib [
      zlib
      zstd
      stdenv.cc.cc
      curl
      openssl
      attr
      libssh
      bzip2
      libxml2
      acl
      libsodium
      util-linux
      xz
      systemd
      libusb1
      libxcrypt-legacy
    ];
    pathsToLink = [ "/lib" ];
  };
  rootfs = buildEnv {
    name = "claude-rootfs";
    paths = [
      dockerTools.caCertificates
      dockerTools.binSh
      dockerTools.usrBinEnv
      gitConfig
      passwd
      group
      nsswitch
      nixConf
      nix-ld-link
      bashInteractive
      coreutils
      git
      ripgrep
      hostname
      fd
      jq
      gnugrep
      gnused
      gawk
      findutils
      diffutils
      gnutar
      gzip
      curl
      lix
      claude-code
      unzip
      which
      xxd
      uv
      ghostty.terminfo
      openssh
      less
      forgejo-cli
      gh
    ];
  };
  # todo: /var/empty?
in
writeShellScriptBin "claude-box" ''
  if [ $# -eq 0 ]; then
    set -- /bin/claude
  fi

  MACHINE_NAME="claude-$(${proquint}/bin/proquint $(od -An -tu4 -N4 /dev/urandom | tr -d ' '))"

  # Start a dedicated ssh-agent and load the claude key
  eval "$(${openssh}/bin/ssh-agent)"
  trap '${openssh}/bin/ssh-agent -k' EXIT
  ${openssh}/bin/ssh-add "$HOME/.ssh/id_ed25519_claude"

  sudo ${systemd}/bin/systemd-nspawn \
    -D ${rootfs} \
    -M "$MACHINE_NAME" \
    --volatile=overlay \
    --bind-ro=/nix/store \
    --bind=/nix/var/nix/daemon-socket \
    --bind-ro=/etc/nix/registry.json \
    --bind="$PWD" \
    --chdir="$PWD" \
    --tmpfs=/home/claude:uid=${uid},gid=${gid},mode=0755 \
    --bind="$HOME/.claude.json":/home/claude/.claude.json \
    --bind="$HOME/.claudebox":/home/claude/.claude \
    --bind="$HOME/.claude/.credentials.json":/home/claude/.claude/.credentials.json \
    --bind="$SSH_AUTH_SOCK:/home/claude/.ssh/sock" \
    --bind-ro="$HOME/.ssh/known_hosts:/home/claude/.ssh/known_hosts" \
    --bind="$HOME/.claudebox/forgejo-keys.json:/home/claude/.local/share/forgejo-cli/keys.json" \
    --user=claude \
    --as-pid2 \
    --background= \
    --setenv=HOME=/home/claude \
    --setenv=USER=claude \
    --setenv=NIX_REMOTE=daemon \
    --setenv=NIX_PATH=nixpkgs=flake:nixpkgs \
    --setenv=SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt \
    --setenv=NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt \
    --setenv=PATH=/home/claude/.local/bin:/home/claude/.nix-profile/bin:/bin:/usr/bin \
    --setenv=TERMINFO_DIRS=/share/terminfo \
    --setenv=NIX_LD=${stdenv.cc.bintools.dynamicLinker} \
    --setenv=NIX_LD_LIBRARY_PATH=${nix-ld-lib-path}/lib \
    --setenv=SSH_AUTH_SOCK=/home/claude/.ssh/sock \
    "$@"
''

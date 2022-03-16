(pkgs: super: {
  # https://github.com/NixOS/nixpkgs/pull/145738
  # tree = super.tree.overrideAttrs (o: {
  #   preConfigure = o.preConfigure + ''
  #     makeFlags+=("CC=$CC")
  #   '';
  #   makeFlags = pkgs.lib.filter (x: x != "CC=$CC") o.makeFlags;
  # });
  yubikey-manager = super.yubikey-manager.overrideAttrs (o: {
    # remove after 7d8d3c71228756406b70e142411295affbbb3fa1 is merged
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace 'cryptography = "^2.1 || ^3.0"' 'cryptography = "*"'
      substituteInPlace "ykman/pcsc/__init__.py" \
        --replace 'pkill' '${pkgs.procps}/bin/pkill'
      '';
  });
  notmuch = super.notmuch.overrideAttrs (o: {
    doCheck = false;
  });
})

(pkgs: super: {
  # https://github.com/NixOS/nixpkgs/pull/145738
  tree = super.tree.overrideAttrs (o: {
    preConfigure = o.preConfigure + ''
      makeFlags+=("CC=$CC")
    '';
    makeFlags = pkgs.lib.filter (x: x != "CC=$CC") o.makeFlags;
  });
})

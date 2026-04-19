{
  listNixFiles =
    dir:
    let
      entries = builtins.readDir dir;
      isNixFile = name: entries.${name} == "regular" && builtins.match ".*\\.nix" name != null;
    in
    map (name: dir + "/${name}") (builtins.filter isNixFile (builtins.attrNames entries));
}

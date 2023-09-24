{ lib, buildYarnPackage }:
buildYarnPackage {
  src = ./.;
  postInstall = ''
    rm -rf $out/yarn-cache $out/bin/yarn
  '';
}

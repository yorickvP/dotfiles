{ buildYarnPackage }:
buildYarnPackage {
  src = ./.;
  postBuild = ''
    yarn install --production --ignore-scripts --prefer-offline
  '';
  postInstall = ''
    rm $out/bin/yarn
    sed -i '/^cd /d' $out/bin/ydeployer
  '';
  meta.mainProgram = "ydeployer";
  passthru.exePath = "/bin/ydeployer";
}

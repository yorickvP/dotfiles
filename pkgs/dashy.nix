{ stdenv, fetchFromGitHub, buildYarnPackage, nodejs }:

buildYarnPackage {
  src = fetchFromGitHub {
    owner = "Lissy93";
    repo = "dashy";
    rev = "edeeb74c6ce1f86ae1806f1839723b640c326ace";
    hash = "sha256-WCnyq0MrsuUDt+owN/Ry5cVbvMmo5GVB0QFdCHZ8mxk=";
  };
  pname = "dashy";
  version = "2023-09-23";
  NODE_OPTIONS="--openssl-legacy-provider";
  yarnBuildMore = "yarn run build --offline";
  # for the widgets, I think you need to
  # cp dashy.yml ./public/conf.yml in the preBuild
  postInstall = ''
    rm -r $out/dist
    mv ./dist $out/dist
    rm -r $out/yarn-cache
    ln -fs /etc/dashy.yml $out/dist/conf.yml
  '';
}

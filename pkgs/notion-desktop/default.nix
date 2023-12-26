{ stdenv, lib, p7zip, fetchurl, electron_26, makeWrapper, buildYarnPackage, python3
, nodejs, makeDesktopItem, copyDesktopItems, jq, runCommand, gzip, xz }:

let
  env = buildYarnPackage {
    src = lib.sourceByRegex ./. [ "^package\.json$" "^yarn\.lock$" ];
    postBuild = "yarn install --production --ignore-scripts --prefer-offline";
  };
  # version should match the version in the electron package
  better-sqlite3 = fetchurl {
    url = "https://registry.npmjs.org/better-sqlite3/-/better-sqlite3-8.5.1.tgz";
    hash = "sha256-AdP6+GiuEne2GMdevHLGciFsubGR9Gczr2QK3W0xO/s=";
  };

in stdenv.mkDerivation rec {
  pname = "notion-desktop";
  version = "2.2.0";

  src = fetchurl {
    url = "https://desktop-release.notion-static.com/Notion%20Setup%20${version}.exe";
    hash = "sha256-bRFW3Dh/Nqh46/F35ANA8wQNQ4T7Kf5Lx9+IpNoBjtE=";
  };

  nativeBuildInputs = [ p7zip makeWrapper python3 nodejs copyDesktopItems jq ];
  npm_config_tarball = electron_26.headers;

  unpackPhase = ''
    runHook preUnpack

    7z e $src \$PLUGINSDIR/app-64.7z
    7z x app-64.7z resources/ version
    rm app-64.7z
    mkdir ./better-sqlite3-source
    tar xzf ${better-sqlite3} -C $_

    runHook postUnpack
  '';
  buildPhase = ''
    runHook preBuild

    ${env}/node_modules/.bin/asar extract resources/app.asar resources/app/

    # replace better-sqlite3 with source
    # check better-sqlite3 version match
    if [ $(jq .version resources/app/node_modules/better-sqlite3/package.json) != $(jq .version ./better-sqlite3-source/package/package.json) ]; then
      echo "better-sqlite3 version mismatch"
      echo "please update to" $(jq .version resources/app/node_modules/better-sqlite3/package.json)
      exit 1
    fi
    rm -r resources/app/node_modules/better-sqlite3
    mv ./better-sqlite3-source/package resources/app/node_modules/better-sqlite3

    # rebuild
    ${env}/node_modules/.bin/electron-rebuild --version ${electron_26.version} --module-dir resources/app/
    # move back into asar.unpacked dir, then discard the unpacked app
    mv ./resources/app/node_modules/better-sqlite3/build/Release/* ./resources/app.asar.unpacked/node_modules/better-sqlite3/build/Release/

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/resources $out/bin
    mv resources/{app.asar,app.asar.unpacked} $out/libexec/resources

    install -Dm755 ./resources/app/icon.ico $out/share/icons/hicolor/32x32/apps/notion-desktop.ico

    makeWrapper ${electron_26}/bin/electron $out/bin/notion-desktop \
      --argv0 notion-desktop \
      --add-flags "$out/libexec/resources/app.asar"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Notion";
      exec = "notion-desktop";
      icon = "notion-desktop";
      desktopName = "Notion";
      categories = [ "Office" ];
    })
  ];

  meta = with lib; {
    description = "Desktop application for Notion.so";
    homepage = "https://www.notion.so/desktop";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with maintainers; [ yorickvP ];
    mainProgram = "notion-desktop";
    sourceProvenance = [ sourceTypes.fromSource ];
  };
}

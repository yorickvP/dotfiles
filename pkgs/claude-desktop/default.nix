# source: https://gist.github.com/edef1c/bac094868ca7b4b6c906272e29f8ef87
{
  lib,
  stdenv,
  fetchurl,
  p7zip,
  libarchive,
  asar,
  electron_33,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "claude-desktop";
  version = "0.7.8";

  src = fetchurl {
    url = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe";
    hash = "sha256-SOO1FkAfcOP50Z4YPyrrpSIi322gQdy9vk0CKdYjMwA=";
  };

  nativeBuildInputs = [
    p7zip
    libarchive
    asar
    makeWrapper
  ];

  unpackPhase = ''
    7z x $src AnthropicClaude-${version}-full.nupkg
    bsdtar xf AnthropicClaude-${version}-full.nupkg --strip-components=3 lib/net45/resources/app.asar{,.unpacked}
    asar e app.asar app
    sourceRoot=app
  '';

  postPatch = ''
    rm node_modules/claude-native/claude-native-binding.node
    echo "module.exports={KeyboardKey:{}}" > node_modules/claude-native/index.js
  '';

  installPhase = ''
    mkdir -p $out
    asar pack . $out/app.asar
    makeWrapper ${lib.getExe electron_33} $out/bin/claude-desktop --add-flags $out/app.asar 
  '';
}

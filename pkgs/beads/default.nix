{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  git,
  icu,
}:
buildGo126Module rec {
  pname = "beads";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "gastownhall";
    repo = "beads";
    rev = "8ec8f705b13eec44ea35a3a220060de835b52736";
    hash = "sha256-L28EzVdkxoDPdg8sOD3RqCd+5lxkWLi2anW8R3csl0E=";
  };

  subPackages = [ "cmd/bd" ];
  doCheck = false;

  vendorHash = "sha256-UCODmlavmZc2/4ltA2g71UvjjNLxEG+g82IFUjNtpdI=";

  env.CGO_CPPFLAGS = "-I${icu.dev}/include";
  env.CGO_LDFLAGS = "-L${icu}/lib";

  nativeBuildInputs = [ git ];

  postInstall = ''
    ln -s bd $out/bin/beads

    mkdir -p $out/share/fish/vendor_completions.d
    mkdir -p $out/share/bash-completion/completions
    mkdir -p $out/share/zsh/site-functions

    $out/bin/bd completion fish > $out/share/fish/vendor_completions.d/bd.fish
    $out/bin/bd completion bash > $out/share/bash-completion/completions/bd
    $out/bin/bd completion zsh > $out/share/zsh/site-functions/_bd
  '';

  meta = with lib; {
    description = "beads (bd) - An issue tracker designed for AI-supervised coding workflows";
    homepage = "https://github.com/gastownhall/beads";
    license = licenses.mit;
    mainProgram = "bd";
  };
}

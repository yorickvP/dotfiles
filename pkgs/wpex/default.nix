{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "wpex";
  version = "0-unstable-2026-04-04";
  src = fetchFromGitHub {
    owner = "codesoap";
    repo = "wpex";
    rev = "1e5c83d08c8a84372cca5b8af3a6eb1f0aea4961";
    hash = "sha256-Fxirq0hFOb9/VV+wEV5GaqubRHUPsRYhJdqv72u3emU=";
  };
  overrideModAttrs = _: {
    preBuild = ''
      go mod tidy
    '';
  };
  vendorHash = "sha256-H2SlAbOGp6atLoWsCE9s0rTwdajuiYDSN+tPT+5Y7a0=";
  meta = {
    description = "A WireGuard packet relay for NAT traversal";
    homepage = "https://github.com/codesoap/wpex";
  };
}

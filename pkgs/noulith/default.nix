{ rustPlatform, fetchFromGitHub, pkg-config, openssl }:
rustPlatform.buildRustPackage rec {
  pname = "noulith";
  version = "20231228";

  src = fetchFromGitHub {
    owner = "betaveros";
    rev = "3bce693335d8170895407846c237b6dad10ef7ec";
    repo = pname;
    hash = "sha256-Ye/Htcp9lrRo80ix4QQ+lDZSmpDSA6t1MCcWL6yTvGg=";
  };
  buildFeatures = [
    "cli"
    "request"
    "crypto"
  ];

  cargoHash = "sha256-9mGswL1QberwXpO0qj7NbyY5zozWj88dwCCY6kQ92uU";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl.dev ];
}

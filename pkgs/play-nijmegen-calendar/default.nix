{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonPackage rec {
  pname = "play-nijmegen-calendar";
  version = "0.1.0";

  src = ./.;

  format = "pyproject";

  buildInputs = with python3.pkgs; [
    setuptools
    setuptools-scm
  ];
  propagatedBuildInputs = with python3.pkgs; [
    beautifulsoup4
    icalendar
    pytz
    requests
  ];

  # If your script is named something other than main.py, adjust this
  postInstall = ''
    mkdir -p $out/bin
    cp $src/main.py $out/bin/play-nijmegen-calendar
    chmod +x $out/bin/play-nijmegen-calendar
  '';

  # Disable tests if you don't have any
  doCheck = false;

  meta = with lib; {
    description = "Generate iCal file for Play Nijmegen events";
    # homepage = "https://github.com/your-github-username/play-nijmegen-calendar";
    license = licenses.mit; # Adjust as needed
    maintainers = with maintainers; [ yorickvp ];
  };
}

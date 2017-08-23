{ stdenv, fetchFromGitHub, python2Packages, gnupg1orig, openssl, git }:

python2Packages.buildPythonApplication rec {
  name = "mailpile-${version}";
  version = "1.0rc1";

  src = fetchFromGitHub {
    owner = "mailpile";
    repo = "Mailpile";
    rev = "release/1.0";
    sha256 = "0hl42ljdzk57ndndff9f1yh08znxwj01kjdmx019vmml0arv0jga";
  };

  postPatch = ''
    substituteInPlace setup.py --replace "data_files.append((dir" "data_files.append(('lib/${python2Packages.python.libPrefix}/site-packages/' + dir"
    patchShebangs scripts
  '';
  PBR_VERSION=version;

  buildInputs = with python2Packages; [ pbr git ];

  propagatedBuildInputs = with python2Packages; [
    cryptography
    pillow jinja2 spambayes python2Packages.lxml
    pgpdump gnupg1orig appdirs
  ];

  postInstall = ''
    wrapProgram $out/bin/mailpile \
      --prefix PATH ":" "${stdenv.lib.makeBinPath [ gnupg1orig openssl ]}" \
      --set MAILPILE_SHARED $out/share/mailpile

  '';

  # No tests were found
  doCheck = false;

  meta = with stdenv.lib; {
    description = "A modern, fast web-mail client with user-friendly encryption and privacy features";
    homepage = https://www.mailpile.is/;
    license = [ licenses.agpl3 ];
    platforms = platforms.linux;
    maintainers = [ maintainers.domenkozar maintainers.yorickvp ];
  };
}

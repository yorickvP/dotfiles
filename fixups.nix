(pkgs: super: {
  # with pkgs.lib.firefoxOverlay; firefoxVariants.firefox-bin // { info = versionInfo firefoxVariants.firefox-bin; }
  firefox-109 = pkgs.lib.firefoxOverlay.firefoxVersion {
    info = {
      chksum = "https://download.cdn.mozilla.net/pub/firefox/releases/109.0/SHA512SUMS";
      chksumSha256 = "0f851278012fb0ed7b7d9fb380a500d3a4dc51b6bc54cae4ec0b8d5bb49540fd";
      chksumSig = "https://download.cdn.mozilla.net/pub/firefox/releases/109.0/SHA512SUMS.asc";
      chksumSigSha256 = "9d1c34b74e7f921b0e10a00afbcb3083699da06c969e45ea1315228b8c613d11";
      file = "linux-x86_64/en-US/firefox-109.0.tar.bz2";
      sha512 = "570e54faf9508fe77ba21e97b2e75198349012498e4339066f99d2059cb6021c0a25c9212706d28bd605dfd9d800587767253bf466a90b3ef94f79334b4e9acc";
      sig = null;
      sigSha512 = null;
      url = "https://download.cdn.mozilla.net/pub/firefox/releases/109.0/linux-x86_64/en-US/firefox-109.0.tar.bz2";
    };
    name = "Firefox";
    release = true;
    version = "109.0";
    wmClass = "firefox";
  };
})

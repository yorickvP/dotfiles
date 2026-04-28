_self: super: {
  libdecor = null;
  imagemagick = super.imagemagick.override {
    libheifSupport = false;
    ghostscript = super.ghostscript.override {
      cupsSupport = false;
    };
  };
}

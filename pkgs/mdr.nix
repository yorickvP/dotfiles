(self: super: {
  libmdr = self.callPackage ({stdenv, fetchFromGitHub, bluez}: stdenv.mkDerivation rec {
    pname = "libmdr";
    version = "0.5.1";
    buildInputs = [ bluez ];
    src = fetchFromGitHub {
      owner = "AndreasOlofsson";
      repo = pname;
      rev = "v${version}";
      sha256 = "1asXrEwv1Bk82sgtOhU+beo2p8B8VBTHw4FP6seIPag=";
    };
    enableParallelBuilding = true;
    installPhase = ''
      install -D libmdr.a $out/lib/libmdr.a
      cp -r include $out
    '';
  }) {};
  mdrd = self.callPackage ({stdenv, fetchFromGitHub, libmdr, pkg-config, glib, bluez}: stdenv.mkDerivation rec {
    pname = "mdrd";
    version = "0.3";
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ libmdr glib bluez ];
    makeFlags = "LIBMDR=${libmdr}/lib/libmdr.a --assume-old=${libmdr}/lib/libmdr.a";
    src = fetchFromGitHub {
      owner = "AndreasOlofsson";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-XAcHtOaG/na9zlPezBSH52J5gF6uhW99vP7TW+ShnzY=";
    };
    
    installPhase = ''
      install -D mdrd $out/bin/mdrd
      mkdir -p $out/share/dbus-1/system-services
      cat > $_/org.mdr.service <<HERE
      [D-Bus Service]
      Name=org.mdr
      Exec=$out/bin/mdrd
      User=root
      SystemdService=dbus-org.mdr.service
      HERE
      mkdir -p $out/share/dbus-1/system.d
      cat > $_/org.mdr.conf <<HERE
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
      <busconfig>
        <!-- Only root can own the service -->
        <policy user="root">
          <allow own="org.mdr"/>
        </policy>
      
        <!-- Allow anyone to invoke methods on the interfaces -->
        <policy context="default">
          <allow send_destination="org.mdr"
                 send_interface="org.mdr"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.NoiseCancelling"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.PowerOff"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.AmbientSoundMode"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.Eq"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.AutoPowerOff"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.KeyFunctions"/>
          <allow send_destination="org.mdr"
                 send_interface="org.mdr.Playback"/>
      
          <allow send_destination="org.mdr"
                 send_interface="org.freedesktop.DBus.Introspectable"/>
          <allow send_destination="org.mdr"
                 send_interface="org.freedesktop.DBus.Properties"/>
        </policy>
      </busconfig>
      HERE
    '';
    enableParallelBuilding = true;
  }) {};
  mdr-manager = self.callPackage ({stdenv, fetchFromGitHub, pkg-config, glib, gtk3}: stdenv.mkDerivation rec {
    pname = "mdr-manager";
    version = "0.3";
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ glib gtk3 ];
    NIX_CFLAGS_COMPILE = "-I${glib.dev}/include/gio-unix-2.0";
    #makeFlags = "LIBMDR=${libmdr}/lib/libmdr.a --assume-old=${libmdr}/lib/libmdr.a";
    src = fetchFromGitHub {
      owner = "AndreasOlofsson";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-ZWXhsGsbGDQlnkZLCbL9MPi5Y7wZIltVyOrkPWImu2c=";
    };
    installPhase = "install -D mdr-manager $out/bin/mdr-manager";
    enableParallelBuilding = true;
  }) {};
})

{ pkgs, ... }: {
  programs = {
    home-manager = {
      enable = true;
      path = https://github.com/rycee/home-manager/archive/master.tar.gz;
    };
    git = {
      enable = true;
      userName = "Yorick van Pelt";
      userEmail = "yorick@yorickvanpelt.nl";
      signing.key = "A36E70F9DC014A15";
      # signing.signByDefault = true;
      extraConfig.help.autocorrect = 5;
      extraConfig.push.default = "simple";
      extraConfig."includeIf \"gitdir:~/serokell/\"".path = "~/serokell/.gitconfig";
      aliases = {
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        st = "status";
        remotes = "remote -v";
        branches = "branch -a";
        tags = "tag";
        stashes = "stash list";
        unstage = "reset -q HEAD --";
        discard = "checkout --";
        uncommit = "reset --mixed HEAD~";
        graph = "log --graph -10 --branches --remotes --tags  --format=format:'%Cgreen%h %Creset• %<(75,trunc)%s (%cN, %cr) %Cred%d' --date-order    ";
        dad = "!curl https://icanhazdadjoke.com/ && git add";
      };
    };

    ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 120;
      controlMaster = "auto";
      matchBlocks = {
        "pub.yori.cc" = {
          user = "public";
          identityFile = "~/.ssh/id_rsa_pub";
          identitiesOnly = true;
        };
        oxygen.hostname = "oxygen.obfusk.ch";
        nyamsas = { hostname = "nyamsas.quezacotl.nl"; port = 1337; };
        phassa = { hostname = "karpenoktem.nl"; port = 33933; };
      };
    };
    bash = {
      enable = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      shellAliases = {
        nr = "nix repl \"<nixpkgs>\"";
        nsp = "nix-shell -p";
      };
      initExtra = "eval $(thefuck --alias)";
    };
  };
  xresources.properties =
    let font = "DejaVu Sans Mono";
        fsize = 11;
        dpi = 192; in
  {
    "URxvt.scrollstyle" = "plain";
    "URxvt.scrollBar_right" = "true";
    "URxvt.perl-ext-common" = "default,matcher,font-size,vtwheel";
    "URxvt.url-launcher" = "xdg-open";
    "URxvt.matcher.button" = "1";
    "URxvt.urgentOnBell" = "True";
    "URxvt.depth" = "32";
    "URxvt.borderColor" = "S_base03";
    # "! URxvt.background" = "[95]#202020";
    "*font" = "xft:${font}:size=${toString fsize}:antialias=true:hinting=true";
    "polybar.font" = "${font}:size=${toString fsize}:antialias=true:hinting=true;2";
    "URxvt.geometry" = "100x30";
    "URxvt.scrollColor" = "S_base0";

    "rofi.font" = "${font} ${toString fsize}";
    "Emacs.font" = "${font}-${toString fsize}";

    "URxvt.font-size.step" = "4";
    "URxvt.keysym.C-equal" = "perl:font-size:increase";
    "URxvt.keysym.C-minus" = "perl:font-size:decrease";

    "Xft.dpi" = dpi;
    "*dpi" = dpi;
  };
  xresources.extraConfig = builtins.readFile (
    pkgs.fetchFromGitHub {
      owner = "solarized";
      repo = "xresources";
      rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
      sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
    } + "/Xresources.light");
  xdg.configFile."streamlink/config".text = ''
    player = mpv --cache 2048
    default-stream = best
  '';
  services = {
    compton = {
      enable = true;
      backend = "glx";
      extraOptions = ''
        glx-no-stencil = true;
        unredir-if-possible = true;
      '';
      # nvidia = ''
      #   paint-on-overlay = true;
      #   glx-no-rebind-pixmap = true;
      #   glx-swap-method = -1;
      #   xrender-sync-fence = true;
      # ''; vsync = "opengl-oml";
    };

  };
}

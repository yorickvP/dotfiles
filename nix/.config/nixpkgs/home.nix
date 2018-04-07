{
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
  xdg.configFile."streamlink/config".text = ''
    player = mpv --cache 2048
    default-stream = best
  '';
}

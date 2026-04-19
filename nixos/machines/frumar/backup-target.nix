{
  users.users.znapzend-blackadder = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWwtQA8qAW24b9suTOdkHpQktWRiipoIQUXPnoxm2NHJpVEI24q6cSGsEjYoEs4Vac2bJ7Q93CASVm/qOSm46AMrpURdN2F6oClA/zKHUsZ9MGBkUXvm+HnspE6CpiGFCPtZyK9FpGm2Flwh/U0fd9txVuuNElERgXMY0GDodM/n4JzP6/9yk1F8WLkkhBHgQmqo2gzbEVtYjfpSQ/FyjcShlip0/EoPqhGM7K/WiaGLkbmtXQi5dFWwFwTzLA6NRsGGW2ag12RzR3ok9uwGIVW6Po8Z/XpwFetQTVl8Sfcn3PWQKKtzFzXmFnfwvgTj4f3EDnQNUDgrg8eIZV4B5QGml3CwwhWwup31kmnha7q+soottzMnUTqopa7RY6bcoMZsMpp0/LqyG5jCyFo7sH3E46YwX6xnB98dlP66DLCVvRBIRy/pxajC6XAIFFnfs1W3oDX17Tq4IqUF42gQEdVcYQ95tb/llrT/k1lEr1YuO/Rspwc1BK/e/6WvPR9KM= root@blackadder"
    ];
    isSystemUser = true;
    group = "znapzend-blackadder";
    useDefaultShell = true;
  };
  users.groups.znapzend-blackadder = { };
}

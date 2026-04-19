{
  services.znapzend = {
    enable = true;
    zetup = {
      "rpool/home-enc" = {
        plan = "1d=>1h,1m=>1w";
        destinations.frumar = {
          host = "znapzend-blackadder@frumar.home.yori.cc";
          dataset = "frumar-new/backup/blackadder";
          plan = "1w=>1d,1y=>1w,10y=>1m,50y=>1y";
        };
      };
    };
  };
}

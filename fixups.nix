(_pkgs: super: {
  electron = super.electron_39;
  electron_38 = super.electron_38.overrideAttrs (o: {
    meta = o.meta // {
      broken = true;
    };
  });
  age-plugin-fido2-hmac = super.age-plugin-fido2-hmac.overrideAttrs {
    src = super.fetchFromGitHub {
      owner = "yorickvP";
      repo = "age-plugin-fido2-hmac";
      rev = "73af5848e2ad46edbeb7d861efb5da9d3390722b";
      hash = "sha256-8VGJdgm1fQ06TmrORH2iSOixK5W7LSrl76VGAjbr5Bw=";
    };
    vendorHash = "sha256-3r/eTaa4kYRXqq7sUZzzGkgcF8lZbPZguoHb6W6t1T0=";
  };
  age-plugin-sss = super.age-plugin-sss.overrideAttrs {
    src = super.fetchFromGitHub {
      owner = "yorickvP";
      repo = "age-plugin-sss";
      rev = "6aa3f406e77eaddefe27b68b0d387bb0df31ea76";
      hash = "sha256-t+A79y3PL7e0Kg6aJKDu8vpaCypEJR3gAaxNi7KOLho=";
    };
    vendorHash = "sha256-Aw7dwro6adluhQXPlZ9RZVGBAmNw539Z3c+a8TmPTXU=";
  };
})

(pkgs: super: {
  electron = super.electron_39;
  electron_38 = super.electron_38.overrideAttrs (o: {
    meta = o.meta // {
      broken = true;
    };
  });
})

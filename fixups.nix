(pkgs: super: {
  electrum = super.electrum.overrideAttrs (o: {
    # todo: remove (194112)
    postPatch = ''
      # make compatible with protobuf4 by easing dependencies ...
      substituteInPlace ./contrib/requirements/requirements.txt \
        --replace "protobuf>=3.12,<4" "protobuf>=3.12"
      # ... and regenerating the paymentrequest_pb2.py file
      protoc --python_out=. electrum/paymentrequest.proto

    '';
  });
  nginxStable = super.nginxStable.override { openssl = pkgs.openssl_1_1; };
})

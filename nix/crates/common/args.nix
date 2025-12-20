{
  lib,
  craneLib,
  pkg-config,
  openssl,
  ...
}:
rec {
  src =
    let
      sqlFilter = path: _type: builtins.match ".*sql$" path != null;
      finalFilter = path: type: (sqlFilter path type) || (craneLib.filterCargoSources path type);
    in
    lib.cleanSourceWith {
      src = ../../../.;
      filter = finalFilter;
      name = "source";
    };

  cargoLock = "${src}/Cargo.lock";
  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];
}

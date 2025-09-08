{
  lib,
  pkgs,
  inputs,
  rust,
  ...
}:
lib.makeScope pkgs.newScope (
  self:
  let
    callCrate = self.newScope rec {
      craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (p: rust.toolchains.default);

      # src -> { `pname`, `version` }
      crateInfo = src: craneLib.crateNameFromCargoToml { cargoToml = "${src}/Cargo.toml"; };
    };
  in
  {
    default = callCrate ./prod.nix { };

    coverage = callCrate ./cov.nix { };
  }
)

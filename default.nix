{
  self ? import ./nix/utils/import-flake.nix { src = ./.; },
  inputs ? self.inputs,
  system ? builtins.currentSystem,
  pkgs ? import inputs.nixpkgs {
    config = { };
    overlays = [ inputs.rust-overlay.overlays.default ];
    inherit system;
  },
  lib ? import "${inputs.nixpkgs}/lib",
}:
lib.makeScope pkgs.newScope (
  self': with self'; {
    inherit
      lib
      pkgs
      self
      system
      inputs
      ;

    devLib = callPackage ./nix/lib.nix { };

    format = callPackage ./nix/formatter.nix { };
    rust = callPackage ./nix/rust.nix { };

    devShells = rust.shells;
    crates = rust.crates // {
      saveFromGC = callPackage ./nix/utils/saveFromGC.nix { };
    };

    flake = {
      inherit devShells;
      inherit (format) formatter;
      inherit (rust) apps;
      packages = lib.filterAttrs (n: v: lib.isDerivation v) crates;
      legacyPackages.lib = devLib;
    };
  }
)

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
let
  scope = lib.makeScope pkgs.newScope (sc: {
    inherit
      lib
      pkgs
      self
      system
      inputs
      ;

    devLib = sc.callPackage ./nix/lib.nix { };

    format = sc.callPackage ./nix/formatter.nix { };
    rust = sc.callPackage ./nix/rust.nix { };

    devShells = sc.rust.shells;
    crates = sc.rust.crates;

    flake = {
      inherit (sc) devShells;
      inherit (sc.format) formatter;
      inherit (sc.rust) apps;
      packages = lib.filterAttrs (n: v: lib.isDerivation v) sc.crates;
      legacyPackages.lib = sc.devLib;
    };
  });
in
scope // scope.crates

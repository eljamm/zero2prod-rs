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
  scope = lib.makeScope pkgs.newScope (s: {
    inherit
      lib
      pkgs
      self
      system
      inputs
      flake
      ;

    devLib = s.callPackage ./nix/lib.nix { };

    format = s.callPackage ./nix/formatter.nix { };
    rust = s.callPackage ./nix/rust.nix { };

    devShells = s.rust.shells;
    crates = s.rust.crates;
  });

  flake = with scope; {
    inherit devShells;
    inherit (format) formatter;
    inherit (rust) apps;
    packages = lib.filterAttrs (n: v: lib.isDerivation v) crates;
    legacyPackages.lib = devLib;
  };

  # return final attribute set (non-recursive)
  finalScope = (scope.packages scope) // {
    # but include the original scope
    inherit scope;
  };
in
finalScope // finalScope.flake.packages

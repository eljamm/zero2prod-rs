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
    apps = s.rust.apps;
  });

  flakeLib = inputs.flake-utils.lib;

  flake = with scope; {
    inherit devShells;
    inherit (format) formatter;
    apps = devLib.filterApps apps;
    packages = lib.filterAttrs (n: v: lib.isDerivation v) crates;
    checks = flakeLib.filterPackages system (flake.packages // flake.apps);
    legacyPackages.lib = devLib;
  };

  # return final attribute set (non-recursive)
  finalScope = (scope.packages scope) // {
    # but include the original scope
    inherit scope;
  };
in
finalScope // finalScope.flake.packages

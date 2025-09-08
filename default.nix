let
  flake-inputs = import (
    fetchTarball "https://github.com/fricklerhandwerk/flake-inputs/tarball/4.1.0"
  );
  inherit (flake-inputs)
    import-flake
    ;
in
{
  self ? import-flake {
    src = ./.;
  },
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
  args = {
    inherit
      lib
      pkgs
      self
      system
      inputs
      ;
    inherit (default)
      formatter
      packages
      rust
      ;
    devLib = default.legacyPackages.lib;
    devShells = default.shells;
  };

  default = rec {
    formatter = import ./nix/formatter.nix args;
    rust = import ./nix/rust.nix args;

    legacyPackages.lib = pkgs.callPackage ./nix/lib.nix { };
    packages = rust.crates // {
      saveFromGC = import ./nix/saveFromGC.nix args;
    };

    inherit (rust) shells;
    inherit flake;
  };

  flake = {
    inherit (default)
      formatter
      legacyPackages
      ;
    inherit (default.rust)
      apps
      ;
    devShells = default.shells;
    packages = lib.filterAttrs (n: v: lib.isDerivation v) default.packages;
  };
in
default // args

{ inputs, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { pkgs, lib, ... }:
    {
      treefmt.config = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          prettier.enable = true;
          rustfmt.enable = true;
          rustfmt.edition = "2024";
          taplo.enable = true; # TOML
          yamlfmt.enable = true;
        };
      };

      pre-commit.check.enable = true;
      pre-commit.settings.hooks.treefmt.enable = true;
    };
}

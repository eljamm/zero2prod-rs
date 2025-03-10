{ inputs, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { self', ... }:
    {
      treefmt.config = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          prettier.enable = true;
          rustfmt = {
            enable = true;
            edition = "2024";
            package = self'.legacyPackages.rust.toolchain.availableComponents.rustfmt;
          };
          taplo.enable = true; # TOML
          yamlfmt.enable = true;
        };
      };

      pre-commit.check.enable = true;
      pre-commit.settings.hooks.treefmt.enable = true;
    };
}

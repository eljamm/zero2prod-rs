{
  perSystem =
    {
      config,
      self',
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = [
          self'.devShells.rust
          self'.devShells.aliases
          config.pre-commit.devShell
          config.treefmt.build.devShell
        ];

        packages = with pkgs; [
          # tools
          cargo-auditable
          cargo-expand # macro expansion
          cargo-tarpaulin # code coverage
          cargo-udeps # unused deps
          bacon

          # dependencies
          openssl
          pkg-config
        ];
      };
    };
}

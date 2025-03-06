{
  perSystem =
    {
      config,
      self',
      pkgs,
      ...
    }:
    let
      nightly = self'.legacyPackages.rust.toolchains.nightly;
      cargo-udeps' = pkgs.writeShellScriptBin "cargo-udeps" ''
        export RUSTC="${nightly}/bin/rustc";
        export CARGO="${nightly}/bin/cargo";
        exec "${pkgs.cargo-udeps}/bin/cargo-udeps" "$@"
      '';
    in
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
          cargo-udeps' # unused deps
          bacon

          # dependencies
          openssl
          pkg-config
        ];
      };
    };
}

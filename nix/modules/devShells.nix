{
  perSystem =
    {
      config,
      self',
      pkgs,
      devLib,
      ...
    }:
    let
      nightly = self'.legacyPackages.rust.toolchains.nightly;

      dependencies = with pkgs; [
        openssl
        pkg-config
        sqlx-cli
      ];
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [
          self'.devShells.aliases
          self'.devShells.fmt
          self'.devShells.rust
        ];

        packages =
          with pkgs;
          [
            # tools
            cargo-auditable
            cargo-deny # scan vulnerabilities
            cargo-expand # macro expansion
            cargo-tarpaulin # code coverage
            bacon

            postgresql
            rainfrog # postgres tui
          ]
          ++ dependencies;
      };

      devShells.ci = pkgs.mkShellNoCC {
        packages =
          with pkgs;
          [
            (pkgs.rust-bin.stable.latest.minimal.override {
              extensions = [
                "clippy"
              ];
            })
            cargo-tarpaulin # code coverage
          ]
          ++ dependencies;
      };

      # nix develop .#udeps --command cargo udeps --all-targets
      devShells.udeps = pkgs.mkShellNoCC {
        packages =
          let
            cargo-udeps' = pkgs.writeShellScriptBin "cargo-udeps" ''
              export RUSTC="${nightly}/bin/rustc";
              export CARGO="${nightly}/bin/cargo";
              exec "${pkgs.cargo-udeps}/bin/cargo-udeps" "$@"
            '';
          in
          [
            cargo-udeps' # unused deps
          ]
          ++ dependencies;
      };

      devShells.fmt = pkgs.mkShellNoCC {
        inputsFrom = [
          config.pre-commit.devShell
          config.treefmt.build.devShell
        ];
      };

      apps = devLib.mkApps {
        # scan vulnerabilities:
        # nix run .#audit
        audit = ''
          ${pkgs.cargo-deny}/bin/cargo-deny check advisories
        '';
      };
    };
}

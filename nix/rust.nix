{
  lib,
  pkgs,
  devLib,
  format,
  callPackage,
  ...
}@args:
lib.makeExtensible (self: {
  crates = callPackage ./crates { };

  packages = with pkgs; rec {
    default = [
      self.toolchains.default
      cargo-auditable
    ]
    ++ deps;

    deps = [
      openssl
      pkg-config
      postgresql
      sqlx-cli
    ];

    dev = [
      bacon
      cargo-deny # scan vulnerabilities
      cargo-expand # macro expansion
      cargo-hack
      cargo-llvm-cov
      cargo-nextest
      cargo-tarpaulin # code coverage
      cargo-udeps # unused deps
      rainfrog # postgres tui
    ]
    ++ default
    ++ aliases;

    ci = [
      self.toolchains.default
      cargo-llvm-cov
    ]
    ++ deps;

    aliases =
      let
        # PostgreSQL
        startdb = "pg_ctl -D \"\${1-postgres}\" start";
        stopdb = "pg_ctl -D \"\${1-postgres}\" stop";

        db-cmd = cmd: ''
          ${startdb}
          ${cmd}
          ${stopdb}
        '';
      in
      devLib.mkAliases {
        # Explain `rustc` errors with markdown formatting
        rexp = {
          text = ''rustc --explain "$1" | sed '/^```/{s//&rust/;:a;n;//!ba}' | rich -m -'';
          runtimeInputs = [ pkgs.rich-cli ];
        };

        # Cargo
        bb = db-cmd "cargo build";
        rr = db-cmd "cargo run";
        tt = db-cmd "cargo test";

        # Nix
        bn.text = ''
          package=$1; shift
          nix build --show-trace --print-build-logs .#"$package" "$@"
        '';
        rn.text = ''
          package=$1; shift
          nix run --show-trace --print-build-logs .#"$package" "$@"
        '';

        ff = format.formatter;

        inherit startdb stopdb;
      };
  };

  apps = devLib.mkApps {
    # scan vulnerabilities:
    # nix run .#audit
    audit = ''
      ${pkgs.cargo-deny}/bin/cargo-deny check advisories
    '';
  };

  shells = {
    default = devLib.mkShellMold {
      packages = [
        format.formatter
        pkgs.pinact # pin GH actions
      ]
      ++ self.packages.dev;
    };

    ci = devLib.mkShellMold {
      packages = self.packages.ci;
    };

    # nix develop .#udeps --command cargo udeps --all-targets
    udeps = pkgs.mkShellNoCC {
      packages =
        let
          cargo-udeps' = pkgs.writeShellScriptBin "cargo-udeps" ''
            export RUSTC="${self.toolchains.nightly}/bin/rustc";
            export CARGO="${self.toolchains.nightly}/bin/cargo";
            exec "${pkgs.cargo-udeps}/bin/cargo-udeps" "$@"
          '';
        in
        [
          cargo-udeps' # unused deps
        ]
        ++ self.packages.deps;
    };
  };

  extensions = {
    default = [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
      "rust-analyzer"
      "llvm-tools-preview"
    ];
  };

  toolchains = {
    default = self.toolchains.stable;
    stable = pkgs.rust-bin.stable.latest.minimal.override { extensions = self.extensions.default; };
    nightly = pkgs.rust-bin.selectLatestNightlyWith (
      toolchain: toolchain.minimal.override { extensions = self.extensions.default; }
    );
  };
})

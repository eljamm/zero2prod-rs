{
  pkgs,
  devLib,
  formatter,
  ...
}@args:
rec {
  crates = import ./crates args;

  packages = with pkgs; rec {
    default = [
      toolchains.default
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
      cargo-llvm-cov
      cargo-tarpaulin # code coverage
      cargo-udeps # unused deps
      rainfrog # postgres tui
    ]
    ++ default
    ++ aliases;

    ci = [
      toolchains.default
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
        br = db-cmd "cargo run";
        bt = db-cmd "cargo test";

        # Nix
        nbb = "nix build --show-trace --print-build-logs";
        nrr = "nix run --show-trace --print-build-logs";

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
    default = pkgs.mkShellNoCC {
      packages = [
        formatter
        pkgs.pinact # pin GH actions
      ]
      ++ packages.dev;
    };

    ci = pkgs.mkShellNoCC {
      packages = packages.ci;
    };

    # nix develop .#udeps --command cargo udeps --all-targets
    udeps = pkgs.mkShellNoCC {
      packages =
        let
          cargo-udeps' = pkgs.writeShellScriptBin "cargo-udeps" ''
            export RUSTC="${toolchains.nightly}/bin/rustc";
            export CARGO="${toolchains.nightly}/bin/cargo";
            exec "${pkgs.cargo-udeps}/bin/cargo-udeps" "$@"
          '';
        in
        [
          cargo-udeps' # unused deps
        ]
        ++ packages.deps;
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
    default = toolchains.stable;
    stable = pkgs.rust-bin.stable.latest.minimal.override { extensions = extensions.default; };
    nightly = pkgs.rust-bin.selectLatestNightlyWith (
      toolchain: toolchain.minimal.override { extensions = extensions.default; }
    );
  };
}

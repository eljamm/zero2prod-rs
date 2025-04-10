{
  perSystem =
    { pkgs, devLib, ... }:
    {
      devShells.aliases = pkgs.mkShellNoCC {
        packages = devLib.mkAliases {
          # Explain `rustc` errors with markdown formatting
          rexp = {
            text = ''rustc --explain "$1" | sed '/^```/{s//&rust/;:a;n;//!ba}' | rich -m -'';
            runtimeInputs = [ pkgs.rich-cli ];
          };

          # Cargo
          bb = "cargo build";
          rr = "cargo run";
          tt = "cargo test";

          # Nix
          nbb = "nix build --show-trace --print-build-logs";
          nrr = "nix run --show-trace --print-build-logs";

          # PostgreSQL
          startdb = "pg_ctl -D \"\${1-postgres}\" start";
          stopdb = "pg_ctl -D \"\${1-postgres}\" stop";
        };
      };
    };
}

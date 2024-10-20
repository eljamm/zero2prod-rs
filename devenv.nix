{ lib, pkgs, ... }:
{
  env.GREET = ''
    =============
      Zero2Prod
    =============
  '';

  packages = with pkgs; [
    bacon
    cargo-audit # vulnerabilities
    cargo-expand # macro expansion
    cargo-tarpaulin # code coverage
    cargo-watch
    openssl
  ];

  cachix.enable = false;

  enterShell = ''
    echo "$GREET"
  '';

  languages.rust = {
    enable = true;
    mold.enable = true; # faster linking
    channel = "stable";
  };

  pre-commit.hooks = {
    clippy.enable = true;
    clippy.settings.allFeatures = true;

    treefmt.enable = true;
    treefmt.settings.formatters = [
      pkgs.nixfmt-rfc-style
      pkgs.rustfmt
    ];
  };

  processes = {
    watch.exec = "cargo watch -x check -x test -x run";
  };

  # See full reference at https://devenv.sh/reference/options/
}

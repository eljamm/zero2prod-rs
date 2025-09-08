{
  lib,
  pkgs,
  inputs,
  system,
  ...
}@args:
let
  git-hooks = import inputs.git-hooks { inherit system; };
  treefmt-nix = import inputs.treefmt-nix;

  treefmt = treefmt-nix.mkWrapper pkgs {
    projectRootFile = "default.nix";
    programs.nixfmt.enable = true;
    programs.actionlint.enable = true;
    programs.rustfmt = {
      enable = true;
      edition = "2024";
      package = args.rust.toolchains.default.availableComponents.rustfmt;
    };
    programs.taplo.enable = true; # TOML
  };

  pre-commit-hook = pkgs.writeShellScriptBin "git-hooks" ''
    if [[ -d .git ]]; then
      ${with git-hooks.lib.git-hooks; pre-commit (wrap.abort-on-change treefmt)}
    fi
  '';

  formatter = pkgs.writeShellApplication {
    name = "formatter";
    runtimeInputs = [ treefmt ];
    text = ''
      # shellcheck disable=all
      shell-hook () {
        ${lib.getExe pre-commit-hook}
      }

      if [[ -d .git ]]; then
        shell-hook
      fi
      treefmt "$@"
    '';
  };
in
formatter

{
  lib,
  pkgs,
  inputs,
  system,
  rust,
  ...
}@args:
let
  git-hooks = import inputs.git-hooks { inherit system; };
  treefmt-nix = import inputs.treefmt-nix;

  treefmt-cfg = {
    projectRootFile = "default.nix";
    programs.nixfmt.enable = true;
    programs.actionlint.enable = true;
    programs.zizmor.enable = true;
    programs.rustfmt = {
      enable = true;
      edition = "2024";
      package = rust.toolchains.default.availableComponents.rustfmt;
    };
    programs.taplo.enable = true; # TOML
  };
  treefmt = treefmt-nix.mkWrapper pkgs treefmt-cfg;
  treefmt-pkgs = (treefmt-nix.evalModule pkgs treefmt-cfg).config.build.devShell.nativeBuildInputs;
in
{
  pre-commit-hook = pkgs.writeShellScriptBin "git-hooks" ''
    if [[ -d .git ]]; then
      ${with git-hooks.lib.git-hooks; pre-commit (wrap.abort-on-change treefmt)}
    fi
  '';

  formatter = treefmt;
  formatter-pkgs = treefmt-pkgs;
}

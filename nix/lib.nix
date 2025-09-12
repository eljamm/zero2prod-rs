{
  lib,
  writeShellApplication,

  mkShell,
  useMoldLinker,
  gccStdenv,
  ...
}:
rec {
  attrsToApp =
    name: value:
    writeShellApplication {
      inherit name;
      text = value.text or (value + " \"$@\"");
      runtimeInputs = value.runtimeInputs or [ ];
    };

  mkAliases = aliases: lib.attrValues (lib.mapAttrs attrsToApp aliases);

  mkApps =
    apps:
    lib.mapAttrs (name: value: {
      type = "app";
      program = attrsToApp name value;
    }) apps;

  mkShellMold =
    attrs:
    mkShell.override {
      stdenv = useMoldLinker gccStdenv;
    } attrs;
}

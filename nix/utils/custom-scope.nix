{
  lib,
  inputs,
  pkgs,
  rust,
  ...
}:

finalScope: prevScope:

let
  customScope =
    newScope: f:
    let
      self = f self // {
        newScope = scope: newScope (self // scope);
        overrideScope = g: customScope newScope (lib.extends g f);
        callPackage = self.newScope { };

        # Compute a scope's fixpoint using `callPackage`
        # Example: finalScope = scope.fix scope;
        # See: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library-fixedPoints
        fix = f;

        callCrate = self.newScope rec {
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (p: rust.toolchains.default);

          # src -> { `pname`, `version` }
          crateInfo = src: craneLib.crateNameFromCargoToml { cargoToml = "${src}/Cargo.toml"; };

          # use mold linker
          stdenv = p: p.stdenvAdapters.useMoldLinker self.clangStdenv;
        };

        call = self.callCrate;

        # Similar to `import`, but aware of `default` scope attributes.
        # The result is not overridable.
        importWith =
          f: file: args:
          let
            result = f file args;
          in
          if lib.isAttrs result then
            removeAttrs result [
              "override"
              "overrideDerivation"
            ]
          else
            # Other results are expected for certain cases (e.g. functions).
            result;

        import = self.importWith self.call;
      };
    in
    self;
in
customScope finalScope prevScope

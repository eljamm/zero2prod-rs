{
  lib,
  devLib,
  pkgs,
  ...
}:
devLib.devScope pkgs.newScope (self: {
  commonArgs = self.import ./common/args.nix { };
  test-config = import ./common/config.nix;

  default = self.callCrate ./prod.nix { };
  coverage = self.callCrate ./cov.nix { };
})

{ pkgs, targets }:

let
  mkTarget = packageSet: {
    inherit packageSet;
    pkgs = packageSet;
    stdenv = packageSet.stdenv;
    callPackage = packageSet.callPackage;
    sdl3 = import ./sdl3.nix {
      inherit pkgs;
      targetPkgs = packageSet;
      android = true;
    };
  };
in
{
  armv7a = mkTarget targets.android.armv7a;
  aarch64 = mkTarget targets.android.aarch64;
  i686 = mkTarget targets.android.i686;
  x86_64 = mkTarget targets.android.x86_64;
}

{ pkgs, targets }:

let
  packageSet = targets.windows;
  sdl3 = import ./sdl3.nix {
    inherit pkgs;
    targetPkgs = packageSet;
    windows = true;
  };
in
{
  inherit packageSet sdl3;
  pkgs = packageSet;
  stdenv = packageSet.stdenv;
  callPackage = packageSet.callPackage;
}

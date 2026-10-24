{ pkgs ? import <nixpkgs> { } }:

let
  fhs = import ./fhs.nix { inherit pkgs; };
in
{
  inherit (fhs) mkFhsPackage;
}

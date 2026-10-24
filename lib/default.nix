{ pkgs ? import <nixpkgs> { } }:

let
  fhs = import ./fhs.nix { inherit pkgs; };
  emscripten = import ./emscripten.nix { inherit pkgs; };
in
{
  inherit (fhs) mkFhsPackage;
  inherit emscripten;
}

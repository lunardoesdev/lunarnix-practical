{ pkgs ? import <nixpkgs> { } }:

let
  targets = import ./targets.nix { inherit pkgs; };
in
{
  inherit targets;
  sdl3 = import ./sdl3.nix;
  windows = import ./windows.nix { inherit pkgs targets; };
  android = import ./android.nix { inherit pkgs targets; };
  fhs = import ./fhs.nix { inherit pkgs; };
  emscripten = import ./emscripten.nix { inherit pkgs; };
  tcc = import ./tcc.nix { inherit pkgs; };
}

{ pkgs }:

let
  emscripten = import ./emscripten.nix { inherit pkgs; };
  tcc = import ./tcc.nix { inherit pkgs; };
  targets = import ./targets.nix { inherit pkgs; };
  fhs = import ./fhs.nix { inherit pkgs; };
in
targets // {
  emscriptenStdenv = emscripten.stdenv;
  emscriptenSdl3 = emscripten.sdl3;
  tccStdenv = tcc.tccStdenv;
  inherit (fhs) mkFhsPackage;
}

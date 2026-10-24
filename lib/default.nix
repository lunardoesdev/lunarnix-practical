{ pkgs }:

let
  emscripten = import ./emscripten.nix { inherit pkgs; };
  tcc = import ./tcc.nix { inherit pkgs; };
  targets = import ./targets.nix {
    inherit pkgs;
    emscriptenPkgs = emscripten;
  };
  fhs = import ./fhs.nix { inherit pkgs; };
in
targets // {
  tccStdenv = tcc.tccStdenv;
  inherit (fhs) mkFhsPackage;
}

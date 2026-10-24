{ pkgs, lunarnix }:

let
  sdl3App = pkgs.callPackage ./examples/sdl3-renderer { };
  fhsHello = import ./examples/fhs-hello { inherit pkgs lunarnix; };

  sdl3Emscripten = pkgs.callPackage ./examples/sdl3-renderer {
    stdenv = lunarnix.emscripten.stdenv;
    sdl3 = lunarnix.emscripten.sdl3;
    buildPackages = pkgs;
  };
in
{
  fhs-hello = fhsHello;

  sdl3-fhs = lunarnix.mkFhsPackage {
    drv = sdl3App;
    name = "sdl3-renderer";
  };

  sdl3-emscripten = sdl3Emscripten;
}

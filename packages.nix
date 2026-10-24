{ pkgs, lunarnix }:

let
  sdl3App = pkgs.callPackage ./examples/sdl3-renderer { };
  fhsHello = import ./examples/fhs-hello { inherit pkgs lunarnix; };

  sdl3Emscripten = lunarnix.emscripten.callPackage ./examples/sdl3-renderer { };
in
{
  fhs-hello = fhsHello;

  sdl3-fhs = lunarnix.mkFhsPackage {
    drv = sdl3App;
    name = "sdl3-renderer";
  };

  sdl3-emscripten = sdl3Emscripten;
}

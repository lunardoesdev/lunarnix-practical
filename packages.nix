{ pkgs, lunarnix }:

let
  sdl3App = pkgs.callPackage ./examples/sdl3-renderer { };
  fhsHello = import ./examples/fhs-hello { inherit pkgs lunarnix; };
  rustEmscriptenLib = lunarnix.emscripten.callPackage ./examples/rust-emscripten-lib { };
in
{
  fhs-hello = fhsHello;

  sdl3-fhs = lunarnix.mkFhsPackage {
    drv = sdl3App;
    name = "sdl3-renderer";
  };

  emscripten-hello = lunarnix.emscripten.callPackage ./examples/emscripten-hello { };

  rust-emscripten-lib = rustEmscriptenLib;

  rust-emscripten = lunarnix.emscripten.callPackage ./examples/rust-emscripten-app {
    rustLib = rustEmscriptenLib;
  };

  rust-sys-app = lunarnix.emscripten.callPackage ./examples/rust-sys-app { };
}

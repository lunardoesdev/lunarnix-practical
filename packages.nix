{ pkgs, lunarnix }:

let
  sdl3App = pkgs.callPackage ./examples/sdl3-renderer { };
  fhsHello = import ./examples/fhs-hello { inherit pkgs lunarnix; };
in
{
  fhs-hello = fhsHello;

  sdl3-fhs = lunarnix.mkFhsPackage {
    drv = sdl3App;
    name = "sdl3-renderer";
  };
}

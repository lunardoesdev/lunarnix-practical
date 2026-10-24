{ stdenv, sdl3, cmake, lib }:

stdenv.mkDerivation {
  pname = "sdl3-renderer";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ sdl3 ];
  cmakeFlags = [ "-DSDL3_DIR=${lib.getDev sdl3}/lib/cmake/SDL3" ];
  doCheck = false;

  meta.mainProgram = "sdl3-renderer";
}

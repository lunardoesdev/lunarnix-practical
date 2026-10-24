{ stdenv, buildPackages, sdl3, lib }:

stdenv.mkDerivation {
  pname = "sdl3-renderer";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ buildPackages.cmake ];
  buildInputs = [ sdl3 ];
  cmakeFlags = [ "-DSDL3_DIR=${lib.getDev sdl3}/lib/cmake/SDL3" ];
  doCheck = false;
  checkPhase = "true";

  configurePhase = "cmakeConfigurePhase";

  meta.mainProgram = "sdl3-renderer";
}

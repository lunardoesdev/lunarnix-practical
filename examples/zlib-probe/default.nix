{ stdenv, buildPackages, zlib }:

stdenv.mkDerivation {
  pname = "zlib-probe";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ buildPackages.cmake ];
  buildInputs = [ zlib ];

  meta.mainProgram = "zlib-probe";
}

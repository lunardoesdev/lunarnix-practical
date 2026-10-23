{ stdenv, zlib, cmake }:

stdenv.mkDerivation {
  pname = "zlib-probe";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ zlib ];

  meta.mainProgram = "zlib-probe";
}

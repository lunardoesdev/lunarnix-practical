{ stdenv, rustLib, zlib, lib }:

stdenv.mkDerivation {
  pname = "rust-emscripten";
  version = "0.1.0";

  dontUnpack = true;

  buildInputs = [ rustLib zlib ];

  buildPhase = ''
    runHook preBuild
    $CC ${rustLib}/lib/librust_emscripten_lib.a -lz \
      -o rust-emscripten.html -sEXIT_RUNTIME=1
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/rust-emscripten"
    cp rust-emscripten.html \
       rust-emscripten.js \
       rust-emscripten.wasm \
       "$out/share/rust-emscripten/"
    runHook postInstall
  '';

  meta = {
    mainProgram = "rust-emscripten.html";
    platforms = lib.platforms.all ++ [ "wasm32-unknown-emscripten" ];
  };
}

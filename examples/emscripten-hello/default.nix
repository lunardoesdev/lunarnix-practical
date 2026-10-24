{ stdenv, zlib, lib }:

stdenv.mkDerivation {
  pname = "emscripten-hello";
  version = "0.1.0";
  src = ./.;

  buildInputs = [ zlib ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    $CC main.c -lz -o emscripten-hello.html -sEXIT_RUNTIME=1
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/emscripten-hello"
    cp emscripten-hello.html \
       emscripten-hello.js \
       emscripten-hello.wasm \
       "$out/share/emscripten-hello/"
    runHook postInstall
  '';

  meta = {
    mainProgram = "emscripten-hello.html";
    platforms = lib.platforms.all ++ [ "wasm32-none" ];
  };
}

{ pkgs, sdl3Wasm, src }:
pkgs.stdenv.mkDerivation {
  pname = "sdl3-renderer-emscripten";
  version = "1.0.0";
  inherit src;

  nativeBuildInputs = [
    pkgs.emscripten
    pkgs.nodejs
    pkgs.pkg-config
  ];
  buildInputs = [ sdl3Wasm ];

  dontConfigure = true;
  doCheck = false;

  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR"
    export EM_CACHE="$TMPDIR/emscripten-cache"
    emcc -O2 -Wall -Wextra \
      $(pkg-config --cflags sdl3) main.c \
      -o sdl3-renderer.html \
      $(pkg-config --libs sdl3) \
      -sALLOW_MEMORY_GROWTH=1 \
      -sEXIT_RUNTIME=1
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/sdl3-renderer"
    cp sdl3-renderer.html sdl3-renderer.js sdl3-renderer.wasm \
      "$out/share/sdl3-renderer/"
    runHook postInstall
  '';

  meta.mainProgram = "sdl3-renderer.html";
}

{ pkgs ? import <nixpkgs> { } }:

let
  inherit (pkgs) lib;

  targets = import ./lib/targets.nix { inherit pkgs; };
  windows = import ./lib/windows.nix { inherit pkgs targets; };
  android = import ./lib/android.nix { inherit pkgs targets; };
  fhs = import ./lib/fhs.nix { inherit pkgs; };
  emscripten = import ./lib/emscripten.nix { inherit pkgs; };
  tcc = import ./lib/tcc.nix { inherit pkgs; };

  sdlSrc = ./examples/sdl3-renderer;
  tccSrc = ./examples/tcc-deps;

  mkSdl3App = import ./lib/sdl3-app.nix { inherit lib; src = sdlSrc; };

  # Native SDL3 (desktop)
  sdl3Native = import ./lib/sdl3.nix {
    inherit pkgs;
    targetPkgs = pkgs;
    fhs = true;
  };

  sdl3LinuxNative = mkSdl3App {
    stdenv = pkgs.stdenv;
    sdl3 = sdl3Native;
    nativeBuildInputs = [ pkgs.pkg-config pkgs.patchelf ];
    postFixup = ''
      patchelf --set-rpath "${lib.makeLibraryPath [ sdl3Native ]}" "$out/bin/sdl3-renderer"
    '';
  };
in
{
  # One app derivation, different stdenvs + different SDL3
  sdl3-windows = mkSdl3App {
    stdenv = windows.stdenv;
    sdl3 = windows.sdl3;
    nativeBuildInputs = [ pkgs.pkg-config ];
    postFixup = ''
      for dll in "$out"/bin/*.dll; do
        [ -L "$dll" ] || continue
        cp -L "$dll" "$dll.tmp"
        rm "$dll"
        mv "$dll.tmp" "$dll"
      done
    '';
  };

  sdl3-linux-native = sdl3LinuxNative;

  # Single FHS wrapper function over any derivation
  sdl3-linux-fhs = fhs.mkFhsPackage {
    drv = sdl3LinuxNative;
    name = "sdl3-renderer";
  };

  # Emscripten as a separate derivation (emscriptenStdenv wraps via buildEmscriptenPackage
  # which adds a strict default checkPhase; use a plain stdenv with emcc instead).
  sdl3-emscripten = import ./lib/emscripten-app.nix {
    inherit pkgs;
    sdl3Wasm = emscripten.sdl3;
    src = sdlSrc;
  };

  sdl3-android-armv7a = mkSdl3App {
    stdenv = android.armv7a.stdenv;
    sdl3 = android.armv7a.sdl3;
    nativeBuildInputs = [ pkgs.pkg-config ];
  };

  sdl3-android-aarch64 = mkSdl3App {
    stdenv = android.aarch64.stdenv;
    sdl3 = android.aarch64.sdl3;
    nativeBuildInputs = [ pkgs.pkg-config ];
  };

  sdl3-android-i686 = mkSdl3App {
    stdenv = android.i686.stdenv;
    sdl3 = android.i686.sdl3;
    nativeBuildInputs = [ pkgs.pkg-config ];
  };

  sdl3-android-x86_64 = mkSdl3App {
    stdenv = android.x86_64.stdenv;
    sdl3 = android.x86_64.sdl3;
    nativeBuildInputs = [ pkgs.pkg-config ];
  };

  tcc-deps = tcc.mkDerivation {
    pname = "tcc-deps";
    version = "1.0.0";
    src = tccSrc;

    nativeBuildInputs = [ pkgs.pkg-config pkgs.patchelf ];
    buildInputs = [ pkgs.zlib pkgs.libpng ];

    hardeningDisable = [ "all" ];
    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      $CC $(pkg-config --cflags zlib libpng) main.c -o tcc-deps \
        $(pkg-config --libs zlib libpng)
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 tcc-deps "$out/bin/tcc-deps"
      runHook postInstall
    '';

    postFixup = ''
      patchelf --set-rpath "${lib.makeLibraryPath [ pkgs.zlib pkgs.libpng ]}" \
        "$out/bin/tcc-deps"
    '';

    meta.mainProgram = "tcc-deps";
  };
}

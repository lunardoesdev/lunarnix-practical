{ pkgs, lunarnix }:

{
  sdl3-linux-native = lunarnix.x86_64-linux.callPackage ./examples/sdl3-renderer { };
  sdl3-windows = lunarnix.x86_64-windows.callPackage ./examples/sdl3-renderer { };
  sdl3-emscripten = import ./examples/sdl3-renderer {
    stdenv = lunarnix.emscriptenStdenv;
    sdl3 = lunarnix.emscriptenSdl3;
    cmake = pkgs.cmake;
    lib = pkgs.lib;
  };

  sdl3-linux-fhs = lunarnix.mkFhsPackage {
    drv = lunarnix.x86_64-linux.callPackage ./examples/sdl3-renderer { };
    name = "sdl3-renderer";
  };

  android-zlib-armv7a = lunarnix.android-armv7a.callPackage ./examples/zlib-probe { };
  android-zlib-aarch64 = lunarnix.android-aarch64.callPackage ./examples/zlib-probe { };
  android-zlib-i686 = lunarnix.android-i686.callPackage ./examples/zlib-probe { };
  android-zlib-x86_64 = lunarnix.android-x86_64.callPackage ./examples/zlib-probe { };

  tcc-deps = lunarnix.tccStdenv.mkDerivation {
    pname = "tcc-deps";
    version = "1.0.0";
    src = ./examples/tcc-deps;
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
      patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.zlib pkgs.libpng ]}" \
        "$out/bin/tcc-deps"
    '';
    meta.mainProgram = "tcc-deps";
  };

  fhs-hello = import ./examples/fhs-hello {
    inherit pkgs lunarnix;
  };
}

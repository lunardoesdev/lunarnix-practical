{ pkgs }:

let
  inherit (pkgs) lib;

  # Emscripten is not a nixpkgs cross system. Use the supported wasm32
  # platform shape and give the stdenv an emcc-based cc.
  wasmPlatform = lib.systems.elaborate {
    config = "wasm32-unknown-none";
  };

  emccCc = pkgs.runCommand "emscripten-cc" { } ''
    mkdir -p "$out/bin" "$out/nix-support"

    ln -s ${pkgs.emscripten}/bin/emcc "$out/bin/cc"
    ln -s ${pkgs.emscripten}/bin/em++ "$out/bin/c++"
    ln -s ${pkgs.emscripten}/bin/emar "$out/bin/ar"
    ln -s ${pkgs.emscripten}/bin/emranlib "$out/bin/ranlib"
    ln -s ${pkgs.emscripten}/bin/emcc "$out/bin/ld"

    cat > "$out/nix-support/setup-hook" <<EOF
    export CC="$out/bin/cc"
    export CXX="$out/bin/c++"
    export AR="$out/bin/ar"
    export RANLIB="$out/bin/ranlib"
    export LD="$out/bin/ld"
    export HOME="\''${TMPDIR:-/tmp}"
    export EM_CACHE="\''${TMPDIR:-/tmp}/emscripten-cache"
    export CMAKE_TOOLCHAIN_FILE="${pkgs.emscripten}/share/emscripten/cmake/Modules/Platform/Emscripten.cmake"
    EOF
  '';

  stdenv = pkgs.stdenv.override {
    buildPlatform = pkgs.stdenv.buildPlatform;
    hostPlatform = wasmPlatform;
    targetPlatform = wasmPlatform;

    cc = emccCc;
    hasCC = true;

    extraBuildInputs = [ ];
    overrides = _: _: { };
    allowedRequisites = null;
  };

  sdl3 = (pkgs.callPackage (pkgs.path + "/pkgs/by-name/sd/sdl3/package.nix") {
    stdenv = stdenv;
    x11Support = false;
    vulkanSupport = false;
    traySupport = false;
  }).overrideAttrs (old: {
    doCheck = false;
    outputs = [ "out" "dev" "lib" ];
    postInstall = "";

    meta = (old.meta or { }) // {
      platforms = lib.platforms.all ++ [ "wasm32-none" ];
    };

    cmakeFlags =
      lib.filter
        (flag:
          !(lib.hasPrefix "-DSDL_TESTS=" flag)
          && !(lib.hasPrefix "-DSDL_INSTALL_TESTS=" flag))
        (old.cmakeFlags or [ ])
      ++ [
        "-DSDL_SHARED=OFF"
        "-DSDL_STATIC=ON"
        "-DSDL_TESTS=OFF"
        "-DSDL_INSTALL_TESTS=OFF"
        "-DSDL_EXAMPLES=OFF"
        "-DSDL_UNIX_CONSOLE_BUILD=ON"
        "-DSDL_OPENGL=ON"
        "-DSDL_OPENGLES=ON"
      ];
  });
in
{
  inherit stdenv sdl3;
}

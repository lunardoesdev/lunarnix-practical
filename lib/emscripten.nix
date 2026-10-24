{ pkgs }:

let
  setupHook = pkgs.runCommand "emscripten-cmake-hook" { } ''
    mkdir -p "$out/nix-support"
    cat > "$out/nix-support/setup-hook" <<EOF
    export HOME="\''${TMPDIR:-/tmp}"
    export EM_CACHE="\''${TMPDIR:-/tmp}/emscripten-cache"
    export CMAKE_TOOLCHAIN_FILE="${pkgs.emscripten}/share/emscripten/cmake/Modules/Platform/Emscripten.cmake"
    EOF
  '';

  sdl3Wasm = pkgs.stdenv.mkDerivation {
    pname = "sdl3";
    version = pkgs.sdl3.version;
    src = pkgs.sdl3.src;

    nativeBuildInputs = [ pkgs.cmake pkgs.emscripten pkgs.ninja setupHook ];
    propagatedBuildInputs = [ setupHook ];

    configurePhase = ''
      runHook preConfigure
      export HOME="$TMPDIR"
      export EM_CACHE="$TMPDIR/emscripten-cache"
      emcmake cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$out" \
        -DSDL_SHARED=OFF \
        -DSDL_STATIC=ON \
        -DSDL_TESTS=OFF \
        -DSDL_INSTALL_TESTS=OFF \
        -DSDL_EXAMPLES=OFF \
        -DSDL_VULKAN=OFF \
        -DSDL_OPENGL=ON \
        -DSDL_OPENGLES=ON
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      cmake --build build --parallel
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cmake --install build
      runHook postInstall
    '';

    doCheck = false;
  };

  emscriptenPkgs = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      packageOverrides = _: {
        stdenv = pkgs.emscriptenStdenv;
        sdl3 = sdl3Wasm;
        # Native build tools come from buildPackages, not the target set.
        buildPackages = pkgs;
      };
    };
  };
in
emscriptenPkgs

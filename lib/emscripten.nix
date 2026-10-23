{ pkgs }:

let
  sdl3 = pkgs.stdenv.mkDerivation {
    pname = "sdl3-wasm";
    version = pkgs.sdl3.version;
    src = pkgs.sdl3.src;

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.emscripten
      pkgs.ninja
    ];

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

    meta = {
      description = "SDL3 built for Emscripten";
    };
  };

  mkDerivation = args:
    pkgs.stdenv.mkDerivation (args // {
      nativeBuildInputs = [
        pkgs.emscripten
        pkgs.nodejs
        pkgs.pkg-config
      ] ++ (args.nativeBuildInputs or [ ]);
      doCheck = args.doCheck or false;
    });
in
{
  inherit sdl3 mkDerivation;
  emscripten = pkgs.emscripten;
  stdenv = pkgs.stdenv // {
    inherit mkDerivation;
  };
}

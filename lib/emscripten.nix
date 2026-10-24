{ pkgs }:

let
  inherit (pkgs) lib;

  emccCc = (pkgs.runCommand "emscripten-cc" { } ''
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
  '').overrideAttrs (old: {
    isGNU = false;
    isClang = true;
    isArocc = false;
    isZig = false;
    isFlang = false;
  });

  emscriptenPkgs = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;

    crossSystem = {
      config = "wasm32-unknown-none";
    };

    config = {
      allowUnsupportedSystem = true;

      replaceCrossStdenv = { baseStdenv, ... }:
        let
          targetStdenv = baseStdenv.override {
            cc = emccCc;
            hasCC = true;
            allowedRequisites = null;
          };
        in
        targetStdenv // {
          mkDerivation = args:
            let
              patch = attrs: attrs // {
                doCheck = false;
                checkPhase = "true";
                cmakeFlags =
                  lib.filter
                    (flag:
                      !(lib.hasPrefix "-DSDL_TESTS=" flag)
                      && !(lib.hasPrefix "-DSDL_INSTALL_TESTS=" flag))
                    (attrs.cmakeFlags or [ ])
                  ++ [
                    "-DSDL_TESTS=OFF"
                    "-DSDL_INSTALL_TESTS=OFF"
                  ];
                postInstall = (attrs.postInstall or "") + ''
                  for output in $outputs; do
                    eval "dir=\$$output"
                    mkdir -p "$dir"
                  done
                '';
              };
            in
            targetStdenv.mkDerivation (
              if builtins.isFunction args then
                finalAttrs: patch (args finalAttrs)
              else
                patch args
            );
        };

      # Global option defaults consumed by callPackage. No package-specific
      # SDL3 definition is needed here.
      packageOverrides = _: {
        x11Support = false;
        vulkanSupport = false;
        traySupport = false;

        # Native build tools, not target packages.
        cmake = pkgs.cmake;
        ninja = pkgs.ninja;
        pkg-config = pkgs.pkg-config;
        validatePkgConfig = pkgs.validatePkgConfig;
      };
    };
  };
in
emscriptenPkgs

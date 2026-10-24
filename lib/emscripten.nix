{ pkgs }:

let
  inherit (pkgs) lib;

  localSystem = pkgs.stdenv.hostPlatform.system;
  crossSystem = {
    config = "wasm32-unknown-none";
  };

  buildPlatform = lib.systems.elaborate localSystem;
  targetPlatform = lib.systems.elaborate crossSystem;

  nativePkgs = import pkgs.path {
    inherit localSystem;
    config.allowUnsupportedSystem = true;
  };

  llvmBintools = nativePkgs.llvmPackages.llvm;

  # Driver package with the names nixpkgs' wrapCCWith/wrapBintoolsWith
  # recognise. The wrappers then provide the standard setup hooks: CC/CXX,
  # AR/RANLIB/LD, -isystem/-L for buildInputs, hardening flags, etc.
  emccTools = (nativePkgs.runCommand "emcc-tools" { } ''
    mkdir -p "$out/bin"

    for tool in gcc g++; do
      case "$tool" in
        gcc) target=emcc ;;
        g++) target=em++ ;;
      esac
      cat > "$out/bin/$tool" <<'EOF'
    #!@shell@
    set -eu
    args=()
    for arg in "$@"; do
      case "$arg" in
        -mtls-dialect=*|-mno-omit-leaf-frame-pointer|-momit-leaf-frame-pointer|-fcf-protection*|-fzero-call-used-regs*) ;;
        *) args+=("$arg") ;;
      esac
    done
    exec @emcc@ "''${args[@]}"
    EOF
      sed -i \
        -e "s|@shell@|${nativePkgs.runtimeShell}|g" \
        -e "s|@emcc@|${nativePkgs.emscripten}/bin/$target|g" \
        "$out/bin/$tool"
      chmod +x "$out/bin/$tool"
    done

    ln -s ${nativePkgs.emscripten}/bin/emar "$out/bin/ar"
    ln -s ${nativePkgs.emscripten}/bin/emranlib "$out/bin/ranlib"
    ln -s ${nativePkgs.emscripten}/bin/emcc "$out/bin/ld"
    ln -s ${nativePkgs.emscripten}/bin/emcc "$out/bin/as"

    ln -s ${llvmBintools}/bin/llvm-nm "$out/bin/nm"
    ln -s ${llvmBintools}/bin/llvm-objcopy "$out/bin/objcopy"
    ln -s ${llvmBintools}/bin/llvm-objdump "$out/bin/objdump"
    ln -s ${llvmBintools}/bin/llvm-readelf "$out/bin/readelf"
    ln -s ${llvmBintools}/bin/llvm-strip "$out/bin/strip"
    ln -s ${llvmBintools}/bin/llvm-strings "$out/bin/strings"
    ln -s ${llvmBintools}/bin/llvm-size "$out/bin/size"
  '').overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      hardeningUnsupportedFlagsByTargetPlatform = _: [
        "fortify"
        "fortify3"
        "shadowstack"
        "stackprotector"
        "stackclashprotection"
        "nostrictaliasing"
        "pacret"
        "strictflexarrays1"
        "strictflexarrays3"
        "pic"
        "strictoverflow"
        "libcxxhardeningfast"
        "libcxxhardeningextensive"
        "glibcxxassertions"
        "format"
        "trivialautovarinit"
        "zerocallusedregs"
        "pie"
        "relro"
        "bindnow"
      ];
    };
  });

  bintools = nativePkgs.wrapBintoolsWith {
    bintools = emccTools;
    libc = null;
  };

  cc = nativePkgs.wrapCCWith {
    cc = emccTools;
    inherit bintools;
    libc = null;
  };

  mesonCross = nativePkgs.writeText "emscripten-meson.ini" ''
    [binaries]
    c = '${cc}/bin/cc'
    cpp = '${cc}/bin/c++'
    ar = '${bintools}/bin/ar'
    strip = '${bintools}/bin/strip'

    [properties]
    needs_exe_wrapper = true
    exe_wrapper = '${nativePkgs.nodejs}/bin/node'

    [host_machine]
    system = 'emscripten'
    cpu_family = 'wasm32'
    cpu = 'wasm32'
    endian = 'little'
  '';

  emscriptenHook = nativePkgs.writeTextDir "nix-support/setup-hook" ''
    # Emscripten-specific environment. CC/CXX/AR/RANLIB/LD and the
    # -isystem/-L flags from buildInputs come from nixpkgs' standard
    # cc-wrapper and bintools-wrapper setup hooks.

    export EMSCRIPTEN="${nativePkgs.emscripten}"
    export EMSCRIPTEN_ROOT="$EMSCRIPTEN/share/emscripten"
    export EMCC="${cc}/bin/cc"
    export EMCXX="${cc}/bin/c++"
    export EMAR="${bintools}/bin/ar"
    export EMRANLIB="${bintools}/bin/ranlib"

    export BUILD_TRIPLET="x86_64-pc-linux-gnu"
    export HOST_TRIPLET="wasm32-unknown-emscripten"
    export TARGET_TRIPLET="$HOST_TRIPLET"
    export HOST_ARCH="wasm32"
    export HOST_OS="emscripten"

    export PKG_CONFIG_ALLOW_CROSS=1
    export EMCONFIGURE_JS=2

    export CMAKE_TOOLCHAIN_FILE="$EMSCRIPTEN_ROOT/cmake/Modules/Platform/Emscripten.cmake"
    export CMAKE_SYSTEM_NAME="Emscripten"
    export CMAKE_SYSTEM_PROCESSOR="wasm32"
    export CMAKE_C_COMPILER="${cc}/bin/cc"
    export CMAKE_CXX_COMPILER="${cc}/bin/c++"
    export CMAKE_AR="${bintools}/bin/ar"
    export CMAKE_RANLIB="${bintools}/bin/ranlib"
    export CMAKE_LINKER="${bintools}/bin/ld"
    export CMAKE_STRIP="${bintools}/bin/strip"
    export CMAKE_NM="${bintools}/bin/nm"
    export CMAKE_OBJCOPY="${bintools}/bin/objcopy"
    export CMAKE_OBJDUMP="${bintools}/bin/objdump"
    export CMAKE_TRY_COMPILE_TARGET_TYPE="STATIC_LIBRARY"
    export CMAKE_POLICY_VERSION_MINIMUM="3.5"
    export THREADS_PREFER_PTHREAD_FLAG="ON"
    export CMAKE_MAKE_PROGRAM="${nativePkgs.gnumake}/bin/make"

    export MESON_CROSS_FILE="${mesonCross}"

    export CARGO_BUILD_TARGET="wasm32-unknown-emscripten"
    export CARGO_TARGET_WASM32_UNKNOWN_EMSCRIPTEN_LINKER="${cc}/bin/cc"
    export CARGO_TARGET_WASM32_UNKNOWN_EMSCRIPTEN_AR="${bintools}/bin/ar"
    export CC_wasm32_unknown_emscripten="${cc}/bin/cc"
    export CXX_wasm32_unknown_emscripten="${cc}/bin/c++"
    export CFLAGS_wasm32_unknown_emscripten="''${CFLAGS:-}"
    export CXXFLAGS_wasm32_unknown_emscripten="''${CXXFLAGS:-}"

    CORES="''${NIX_BUILD_CORES:-1}"
    export CORES
    export MAKEFLAGS="-j$CORES"
    export NINJAJOBS="$CORES"
    export CMAKE_BUILD_PARALLEL_LEVEL="$CORES"
    export EMCC_CORES="$CORES"

    export HOME="''${TMPDIR:-/tmp}"
    export EM_CACHE="''${TMPDIR:-/tmp}/emscripten-cache"
  '';

  emscriptenPkgs = import pkgs.path {
    inherit localSystem crossSystem;

    config = {
      allowUnsupportedSystem = true;

      replaceCrossStdenv = { baseStdenv, ... }:
        let
          emscriptenPlatform = baseStdenv.hostPlatform // {
            config = "wasm32-unknown-emscripten";
            system = "wasm32-unknown-emscripten";
            isEmscripten = true;
            isWasm = true;
            isNone = false;
            parsed = baseStdenv.hostPlatform.parsed // {
              kernel = {
                name = "emscripten";
                families = { };
                execFormat = { name = "wasm"; };
              };
            };
          };

          targetStdenv = baseStdenv.override (old: {
            hostPlatform = emscriptenPlatform;
            targetPlatform = emscriptenPlatform;

            inherit cc;
            hasCC = true;
            allowedRequisites = null;
            extraNativeBuildInputs =
              (old.extraNativeBuildInputs or [ ]) ++ [ emscriptenHook ];
          });
        in
        targetStdenv // {
          mkDerivation = args:
            let
              patch = attrs: attrs // {
                doCheck = false;
                checkPhase = "true";
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

      packageOverrides = _: {
        shared = false;
      };
    };
  };
in
emscriptenPkgs

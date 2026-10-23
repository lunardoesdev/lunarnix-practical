{ pkgs, packages }:

let
  inherit (pkgs) lib;

  tools = [
    pkgs.binutils
    pkgs.file
  ];

  check = name: script: pkgs.runCommand name { nativeBuildInputs = tools; } ''
    set -eu
    ${script}
    mkdir -p "$out"
  '';

  androidCheck = name: expected:
    check "check-sdl3-android-${name}" ''
      binary="${packages."sdl3-android-${name}"}/bin/sdl3-renderer"
      file "$binary" | grep -F '${expected}'
      file "$binary" | grep -F 'for Android 35'
      readelf -h "$binary" | grep -F 'DYN'
      readelf -d "$binary" | grep -F 'libSDL3.so'
    '';
in
{
  sdl3-windows-artifacts = check "check-sdl3-windows" ''
    file "${packages.sdl3-windows}/bin/sdl3-renderer.exe" | grep -F 'PE32+'
    file "${packages.sdl3-windows}/bin/SDL3.dll" | grep -F 'PE32+'
    test ! -L "${packages.sdl3-windows}/bin/SDL3.dll"
  '';

  sdl3-linux-fhs-artifacts = check "check-sdl3-linux-fhs" ''
    root="${packages.sdl3-linux-fhs}"

    test -x "$root/AppRun"
    test -x "$root/bin/sdl3-renderer"
    test -x "$root/shared/bin/sdl3-renderer"
    test -f "$root/lib/ld-linux-x86-64.so.2"
    test -f "$root/lib/libSDL3.so.0"

    if readelf -d "$root/shared/bin/sdl3-renderer" | grep -Eq 'RPATH|RUNPATH'; then
      echo "bundled executable still has an rpath" >&2
      exit 1
    fi

    for pattern in 'libGL.so*' 'libEGL.so*' 'libGLX.so*' 'libgbm.so*' 'libvulkan.so*' 'libdrm.so*'; do
      if compgen -G "$root/lib/$pattern" > /dev/null; then
        echo "host graphics library was bundled: $pattern" >&2
        exit 1
      fi
    done
  '';

  sdl3-emscripten-artifacts = check "check-sdl3-emscripten" ''
    root="${packages.sdl3-emscripten}/share/sdl3-renderer"
    test -f "$root/sdl3-renderer.html"
    test -f "$root/sdl3-renderer.js"
    test -f "$root/sdl3-renderer.wasm"
    file "$root/sdl3-renderer.wasm" | grep -F 'WebAssembly'
    grep -q 'createSDL3' "$root/sdl3-renderer.js" || grep -q 'SDL3' "$root/sdl3-renderer.js"
  '';

  sdl3-android-armv7a-artifacts = androidCheck "armv7a" "ARM,";
  sdl3-android-aarch64-artifacts = androidCheck "aarch64" "ARM aarch64";
  sdl3-android-i686-artifacts = check "check-sdl3-android-i686" ''
    binary="${packages."sdl3-android-i686"}/bin/sdl3-renderer"
    file "$binary" | grep -E 'Intel|i386'
    file "$binary" | grep -F 'for Android 35'
    readelf -h "$binary" | grep -F 'DYN'
    readelf -d "$binary" | grep -F 'libSDL3.so'
  '';
  sdl3-android-x86_64-artifacts = androidCheck "x86_64" "x86-64";

  tcc-deps-run = check "check-tcc-deps" ''
    output="$(${packages.tcc-deps}/bin/tcc-deps)"
    echo "$output"
    echo "$output" | grep -F 'zlib='
    echo "$output" | grep -F 'libpng='
  '';
}

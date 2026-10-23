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
    check "check-android-zlib-${name}" ''
      binary="${packages."android-zlib-${name}"}/bin/zlib-probe"
      file "$binary" | grep -F '${expected}'
      file "$binary" | grep -F 'for Android 35'
      readelf -h "$binary" | grep -F 'DYN'
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
    test -x "$root/sdl3-renderer-x86_64.AppImage"
    file "$root/sdl3-renderer-x86_64.AppImage" | grep -F 'ELF 64-bit'
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

  android-zlib-armv7a-artifacts = androidCheck "armv7a" "ARM,";
  android-zlib-aarch64-artifacts = androidCheck "aarch64" "ARM aarch64";
  android-zlib-i686-artifacts = androidCheck "i686" "Intel i386";
  android-zlib-x86_64-artifacts = androidCheck "x86_64" "x86-64";

  tcc-deps-run = check "check-tcc-deps" ''
    output="$(${packages.tcc-deps}/bin/tcc-deps)"
    echo "$output"
    echo "$output" | grep -F 'zlib='
    echo "$output" | grep -F 'libpng='
  '';

  fhs-hello-run = check "check-fhs-hello" ''
    output="$(${packages.fhs-hello}/bin/fhs-hello)"
    echo "$output"
    echo "$output" | grep -F 'hello from a portable FHS bundle'
  '';

  fhs-hello-appimage-run = check "check-fhs-hello-appimage" ''
    output="$(${packages.fhs-hello}/fhs-hello-x86_64.AppImage)"
    echo "$output"
    echo "$output" | grep -F 'hello from a portable FHS bundle'
  '';
}

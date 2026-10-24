{ pkgs, packages }:

let
  tools = [
    pkgs.binutils
    pkgs.file
  ];

  check = name: script: pkgs.runCommand name { nativeBuildInputs = tools; } ''
    set -eu
    ${script}
    mkdir -p "$out"
  '';
in
{
  fhs-hello-run = check "check-fhs-hello" ''
    output="$(${packages.fhs-hello}/bin/fhs-hello)"
    echo "$output"
    echo "$output" | grep -F 'hello from a portable FHS bundle'
  '';

  sdl3-fhs-artifacts = check "check-sdl3-fhs" ''
    app="${packages.sdl3-fhs}/bin/sdl3-renderer"
    test -x "$app"
    file "$app" | grep -F 'ELF 64-bit'
  '';

  sdl3-emscripten-artifacts = check "check-sdl3-emscripten" ''
    root="${packages.sdl3-emscripten}/share/sdl3-renderer"
    test -f "$root/sdl3-renderer.html"
    test -f "$root/sdl3-renderer.js"
    test -f "$root/sdl3-renderer.wasm"
    file "$root/sdl3-renderer.wasm" | grep -F 'WebAssembly'
  '';
}

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

  emscripten-hello-artifacts = check "check-emscripten-hello" ''
    root="${packages.emscripten-hello}/share/emscripten-hello"
    test -f "$root/emscripten-hello.html"
    test -f "$root/emscripten-hello.js"
    test -f "$root/emscripten-hello.wasm"
    file "$root/emscripten-hello.wasm" | grep -F 'WebAssembly'
  '';
}

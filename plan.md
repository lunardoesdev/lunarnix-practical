# lunarnix-practical

Portable Linux bundles and a proper Emscripten stdenv.

## FHS target

`mkFhsPackage` turns an ordinary Linux derivation into one self-contained
AppImage:

- output is a single executable: `$out/bin/<name>`;
- inner launcher: pinned **sharun**;
- outer runtime: pinned **uruntime** with `URUNTIME_EXTRACT=2`;
- host graphics stack (GL/EGL/Vulkan/DRM/Mesa) stays on the host by default.

### How it is built

1. Stage an AppDir with the real executable under `shared/bin`.
2. Install sharun as `sharun`, `AppRun`, and the public `bin` entry.
3. Copy glibc and the executable's `DT_NEEDED` closure, excluding host graphics
   libraries when `hostGraphics = true`.
4. Remove RPATH/RUNPATH from bundled ELF files.
5. Pack the AppDir with `mksquashfs`.
6. Prepend uruntime and write `$out/bin/<name>`.

## Emscripten target

Emscripten is not a nixpkgs `crossSystem`. `pkgs.emscriptenStdenv` is an
autotools wrapper, not a normal compiler stdenv. This repo assembles a proper
Emscripten stdenv from parts, like a bare-metal cross stdenv:

- a WASM target platform;
- a `cc` package with `emcc`, `em++`, `emar`, `emranlib`, and a setup hook
  exporting `CC`, `AR`, `RANLIB`, and `CMAKE_TOOLCHAIN_FILE`;
- `pkgs.stdenv.override { hostPlatform = ...; cc = ...; }`.

`sdl3` is the real nixpkgs SDL3 package built with that stdenv; there is no
custom SDL3 definition in this repo.

```nix
let
  emscripten = lunarnix.emscripten;
in
pkgs.callPackage ./examples/sdl3-renderer {
  stdenv = emscripten.stdenv;
  sdl3 = emscripten.sdl3;
  buildPackages = pkgs;
}
```

The result contains `sdl3-renderer.html`, `.js`, and `.wasm` under
`share/sdl3-renderer`. Serve that directory over HTTP to run it in a browser.

## Layout

```text
flake.nix
default.nix
lib/
  default.nix
  fhs.nix
  emscripten.nix
examples/
  fhs-hello/
  sdl3-renderer/
checks/
  default.nix
```

## Verification

- `nix flake check` runs the FHS hello AppImage.
- The SDL3 FHS artifact is checked as a single ELF executable.
- The Emscripten artifact is checked for `.html`, `.js`, and WebAssembly.
- Manual run: `nix build .#sdl3-fhs`, then run under Wayland/X11 with OpenGL.

## Version control

Use Jujutsu:

```sh
jj commit -m "message"
```

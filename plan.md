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

Emscripten is a real nixpkgs cross system:

```nix
crossSystem = { config = "wasm32-unknown-none"; };
```

The cross stdenv is replaced via nixpkgs' `config.replaceCrossStdenv` hook with
an `emcc`-based compiler package. Native build tools stay in `buildPackages`.

`sdl3` is not defined anywhere in the library. The demo application only lists
`buildInputs = [ sdl3 ]`, and the cross package set's own `callPackage` resolves
the unmodified nixpkgs SDL3 built with the Emscripten stdenv.

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

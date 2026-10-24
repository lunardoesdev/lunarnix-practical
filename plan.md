# lunarnix-practical

Practical Nix package sets for cross-compiling C examples, plus an FHS bundle
function and a TinyCC stdenv.

## Target matrix

| Target | Public interface | Demo |
| --- | --- | --- |
| `x86_64-linux` | Native nixpkgs package set | SDL3 renderer |
| `x86_64-windows` | `pkgsCross.mingwW64` | SDL3 renderer |
| `emscripten` | full package set with `emscriptenStdenv` via `packageOverrides` | SDL3 renderer |
| Android armv7a/aarch64/i686/x86_64 | NDK 29 / API 35 package sets | zlib probe |
| FHS Linux | `mkFhsPackage` wraps ordinary derivations | SDL3 renderer and hello demo |
| Linux/TinyCC | custom TinyCC stdenv | zlib + libpng probe |

Nixpkgs does not define an Emscripten cross system or provide an SDL3 Emscripten
package. This repo creates an Emscripten package set using
`config.packageOverrides` with `pkgs.emscriptenStdenv`, so `callPackage` resolves
the Emscripten stdenv and SDL3 normally. Its SDL3 is built from nixpkgs' SDL3
source with Emscripten's CMake toolchain.

The Android package sets use explicit `crossSystem` settings because the
nixpkgs prebuilt aliases use a different NDK version and do not cover all four
ABIs. Android deliberately uses zlib rather than SDL3.

## Dependency policy

- App sources use ordinary CMake projects and regular Nix package inputs.
- SDL3 is stock nixpkgs SDL3 for Linux and Windows.
- Emscripten SDL3 is built from nixpkgs source because there is no stock wasm
  SDL3 package.
- Android examples consume stock target `zlib`.
- No hardcoded store paths in C source or shell build commands.

## FHS packaging

`mkFhsPackage` accepts an ordinary derivation and outputs one executable at
`$out/bin/<name>` (no `.AppImage` extension). `hostGraphics` defaults to true,
so GL/Vulkan/DRM/Mesa remain host-provided. The build stages a sharun FHS AppDir,
then combines its SquashFS image with pinned uruntime. Sharun launches the real
binary inside the image; uruntime is the outer self-extracting AppImage runtime
with extraction fallback when FUSE is unavailable.

## Verification

- Build and inspect Windows PE, Android ELF, and Emscripten WASM outputs.
- `nix flake check` covers all artifact checks and runnable native probes.
- Run the FHS SDL3 app on Wayland and Xwayland, confirming renderer and frames.
- Run the TCC zlib/libpng probe and the FHS hello demo.

## Version control

Use Jujutsu for logical commits:

```sh
jj commit -m "message"
```

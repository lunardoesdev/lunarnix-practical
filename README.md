# lunarnix-practical

Target nixpkgs package sets for Windows, Android, plus native Linux; an FHS
bundle function; and examples built with SDL3, zlib, Emscripten, and TinyCC.

## Import and use a target package set

Add lunarnix as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lunarnix.url = "github:lunardoesdev/lunarnix-practical";
  };

  outputs = { self, nixpkgs, lunarnix }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      packages.x86_64-linux.my-app =
        lunarnix.x86_64-windows.callPackage ./my-app { };
    };
}
```

`lunarnix.x86_64-linux`, `lunarnix.x86_64-windows`, and
`lunarnix.android-{armv7a,aarch64,i686,x86_64}` are nixpkgs package sets. Use
their ordinary `callPackage` and dependencies; for example, a target package
can take `{ stdenv, zlib, cmake }` and list `zlib` in `buildInputs`.

The Android package sets use NDK 29 / API 35. Nixpkgs does not provide all four
Android ABI aliases, so the missing sets are imported from the pinned nixpkgs
source with explicit `crossSystem` values.

## SDL3 demo

[`examples/sdl3-renderer`](examples/sdl3-renderer) is a regular CMake package:

```nix
{ stdenv, buildPackages, sdl3, lib }:
stdenv.mkDerivation {
  pname = "sdl3-renderer";
  version = "1.0.0";
  src = ./.;
  nativeBuildInputs = [ buildPackages.cmake ];
  buildInputs = [ sdl3 ];
  cmakeFlags = [ "-DSDL3_DIR=${lib.getDev sdl3}/lib/cmake/SDL3" ];
}
```

Build it unchanged with each target package set's normal `callPackage`:

```nix
lunarnix.x86_64-linux.callPackage ./examples/sdl3-renderer { }
lunarnix.x86_64-windows.callPackage ./examples/sdl3-renderer { }
lunarnix.emscripten.callPackage ./examples/sdl3-renderer { }
```

CMake handles the executable and runtime-library install. Linux and Windows
use their stock nixpkgs SDL3 packages.

### Emscripten

Nixpkgs has no `pkgsCross.emscripten` and no stock Emscripten SDL3 package. This
repo builds the package set with `config.packageOverrides`, which is nixpkgs's
supported hook for replacing `stdenv` after bootstrapping. The set uses
`pkgs.emscriptenStdenv` and its `sdl3` is built from nixpkgs' SDL3 source with
Emscripten's CMake toolchain. Native build tools such as `cmake` come from
`buildPackages`, so they stay host binaries rather than being rebuilt with
emcc. The app uses the same `callPackage` call as every other target.

## Android zlib demo

Android uses a non-SDL CMake program in [`examples/zlib-probe`](examples/zlib-probe).
It is built with each package set's stock `zlib`:

```nix
lunarnix.android-aarch64.callPackage ./examples/zlib-probe { }
```

## FHS bundle demo

[`examples/fhs-hello`](examples/fhs-hello) first defines an ordinary native
derivation, then passes it to the one `mkFhsPackage` function:

```nix
lunarnix.mkFhsPackage {
  drv = myApp;
  name = "my-app";
  # hostGraphics defaults to true; GL/Vulkan/DRM/Mesa stay host-provided.
}
```

The derivation output contains exactly one executable: `$out/bin/my-app`, a
single-file AppImage with no extension. During the build, the FHS AppDir is
staged and packed into SquashFS. Sharun is its inner launcher; pinned uruntime
is prepended as the outer AppImage runtime. Its policy tries FUSE and falls
back to extraction, so FUSE is not required.

Build and run the demo:

```sh
nix build .#fhs-hello
./result/bin/fhs-hello
```

## TinyCC

`tccStdenv` is a native custom stdenv for C-only packages. The `tcc-deps`
example uses regular native zlib and libpng inputs.

## Build and verify

```sh
nix build .#sdl3-linux-native
nix build .#sdl3-linux-fhs
nix build .#sdl3-windows
nix build .#sdl3-emscripten
nix build .#android-zlib-aarch64
nix build .#tcc-deps
nix flake check
```

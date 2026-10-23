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
{ stdenv, sdl3, cmake, lib }:
stdenv.mkDerivation {
  pname = "sdl3-renderer";
  version = "1.0.0";
  src = ./.;
  nativeBuildInputs = [ cmake ];
  buildInputs = [ sdl3 ];
  cmakeFlags = [ "-DSDL3_DIR=${lib.getDev sdl3}/lib/cmake/SDL3" ];
}
```

Build it unchanged for Linux and Windows with the target package set's normal
`callPackage`:

```nix
lunarnix.x86_64-linux.callPackage ./examples/sdl3-renderer { }
lunarnix.x86_64-windows.callPackage ./examples/sdl3-renderer { }
```

CMake handles the executable and runtime-library install. Linux and Windows
use their stock nixpkgs SDL3 packages.

### Emscripten exception

Nixpkgs has no `pkgsCross.emscripten` and no Emscripten SDL3 package. Importing
nixpkgs with its stdenv replaced fails during nixpkgs' bootstrap-stage checks,
so Emscripten is exposed as `emscriptenStdenv` plus `emscriptenSdl3`, not falsely
presented as a full package set. The SDL3 library is built from nixpkgs' SDL3
source using Emscripten's supported CMake toolchain.

The example uses the same CMake project:

```nix
import ./examples/sdl3-renderer {
  stdenv = lunarnix.emscriptenStdenv;
  sdl3 = lunarnix.emscriptenSdl3;
  cmake = pkgs.cmake;
  lib = pkgs.lib;
}
```

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

The output contains the sharun-based FHS AppDir and `my-app-x86_64.AppImage`.
Sharun is the AppDir launcher; pinned uruntime is combined with a SquashFS
image of that AppDir to create the self-extracting AppImage. Its policy tries
FUSE and falls back to extraction, so FUSE is not required.

Build and run the demo:

```sh
nix build .#fhs-hello
./result/bin/fhs-hello
./result/fhs-hello-x86_64.AppImage
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

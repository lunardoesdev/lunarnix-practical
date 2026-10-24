# lunarnix-practical

Portable Linux AppImage bundles built from ordinary Nix derivations, using
**sharun** as the inner launcher and **uruntime** as the outer AppImage runtime.

`mkFhsPackage` produces exactly one executable: `$out/bin/<name>` (no
`.AppImage` suffix). It runs on ordinary glibc distributions without Nix and
uses the host GPU drivers.

## Use it

Add the flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lunarnix.url = "github:lunardoesdev/lunarnix-practical";
  };

  outputs = { self, nixpkgs, lunarnix }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      myApp = pkgs.stdenv.mkDerivation {
        pname = "my-app";
        version = "1.0";
        src = ./src;
        # ... normal Nix build ...
        meta.mainProgram = "my-app";
      };
    in {
      packages.x86_64-linux.my-app =
        lunarnix.mkFhsPackage {
          drv = myApp;
          name = "my-app";
        };
    };
}
```

Build:

```sh
nix build .#my-app
./result/bin/my-app
```

`hostGraphics` defaults to `true`: GL/EGL/Vulkan/DRM/Mesa stay on the host.
Pass `hostGraphics = false` only if you intentionally want to bundle them.

## How the bundle is made

1. The derivation is copied to an AppDir at `shared/bin/<mainProgram>`.
2. `sharun` is installed as the AppDir's `sharun`, `AppRun`, and `bin/<name>`.
3. glibc and the executable's non-graphics `DT_NEEDED` closure are bundled.
4. RPATH/RUNPATH is removed from bundled ELF files.
5. The AppDir is packed with `mksquashfs`.
6. Pinned `uruntime` is prepended to the SquashFS image, and
   `URUNTIME_EXTRACT=2` makes it try FUSE and otherwise extract, so the
   AppImage works without FUSE.

At runtime sharun invokes the bundled loader with the bundled libraries, then
falls back to host library paths for the GPU driver stack. The result is a
single self-contained executable.

## Demos

```sh
nix build .#fhs-hello
./result/bin/fhs-hello

nix build .#sdl3-fhs
./result/bin/sdl3-renderer --renderer opengl --seconds 1
```

The SDL3 demo is a normal native CMake package wrapped by `mkFhsPackage`; it
uses stock nixpkgs SDL3 and requires a working host GL driver.

## Checks

```sh
nix flake check
```

The checks run the FHS hello AppImage and verify the SDL3 FHS artifact.

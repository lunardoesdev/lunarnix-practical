# lunarnix-practical

Portable Linux FHS bundles plus a proper Emscripten cross environment.

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

`lunarnix.emscripten` is a full nixpkgs package set built as a cross system:

```nix
crossSystem = { config = "wasm32-unknown-none"; };
```

The cross stdenv is replaced through nixpkgs' `config.replaceCrossStdenv`
hook. The compiler and binutils are ordinary nixpkgs cc/bintools wrappers
around `emcc`/`emar`/`emranlib`, so the standard nixpkgs setup hooks work:

- `CC`, `CXX`, `AR`, `RANLIB`, `LD` and the other tools;
- `-isystem` / `-L` flags generated from `buildInputs`;
- hardening flags (with unsupported ones filtered);
- `NIX_CFLAGS_COMPILE` / `NIX_LDFLAGS`.

An additional setup hook exports the Emscripten-specific environment:
`EMCC`, `EMSCRIPTEN_ROOT`, build/host/target triplets, `CMAKE_*`, Meson cross
file, Cargo target/linker/`cc`-crate variables, `PKG_CONFIG_ALLOW_CROSS`, and
parallelism (`EMCC_CORES`, `MAKEFLAGS`, ...).

Dependencies are used the standard way:

```nix
{ stdenv, zlib }:
stdenv.mkDerivation {
  src = ./.;
  buildInputs = [ zlib ];
  buildPhase = ''$CC main.c -lz -o app.html'';
}
```

and the package is built with:

```nix
lunarnix.emscripten.callPackage ./app { }
```

No manual `stdenv`, `zlib`, `lib`, `-I`, or `-L` passing is required.

## Demos

```sh
nix build .#fhs-hello
./result/bin/fhs-hello

nix build .#sdl3-fhs
./result/bin/sdl3-renderer --renderer opengl --seconds 1

nix build .#emscripten-hello
```

The SDL3 demo is a normal native CMake package wrapped by `mkFhsPackage`; it
uses stock nixpkgs SDL3 and requires a working host GL driver.

`emscripten-hello` is a standard derivation with `buildInputs = [ zlib ]`;
it produces `emscripten-hello.html`, `.js`, and `.wasm`.

## Checks

```sh
nix flake check
```

The checks run the FHS hello AppImage, verify the SDL3 FHS artifact, and check
the Emscripten `.html`/`.js`/`.wasm` output.

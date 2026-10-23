# lunarnix-practical

A reusable matrix of Nix stdenvs and packaging helpers for practical cross-platform C builds.

## Targets

| Target | Implementation | Example |
| --- | --- | --- |
| `x86_64-windows` | `pkgsCross.mingwW64` | SDL3 renderer probe |
| `x86_64-linux-fhs` | `mkFhsPackage` runtime bundle | SDL3 + OpenGL host-driver probe |
| `emscripten` | `emscriptenStdenv` adapter + wasm SDL3 | SDL3 renderer probe |
| `armv7a-android` | NDK 29 prebuilt toolchain | SDL3 renderer probe |
| `aarch64-android` | NDK 29 prebuilt toolchain | SDL3 renderer probe |
| `i686-android` | NDK 29 prebuilt toolchain | SDL3 renderer probe |
| `x86_64-android` | NDK 29 prebuilt toolchain | SDL3 renderer probe |
| `x86_64-linux-tcc` | tinycc-based stdenv | zlib + libpng dependency probe |

Android uses API 35 and NDK r29. The four package sets are built from explicit
`crossSystem` definitions rather than relying on the two prebuilt aliases in
nixpkgs.

## Dependency policy

Every example uses ordinary Nix derivation dependency mechanisms:

- target libraries in `buildInputs`
- build-time tools in `nativeBuildInputs`
- `pkg-config` where the library provides a `.pc` file
- no hardcoded `/nix/store/...` include or library paths in app build commands

The TCC example intentionally does not use SDL3. It uses zlib and libpng so the
TCC stdenv is exercised with real dependencies while staying within TCC's
C-only capabilities.

## Layout

```text
flake.nix
default.nix
plan.md
README.md
lib/
  default.nix
  android.nix
  emscripten.nix
  fhs.nix
  sdl3.nix
  tcc.nix
  targets.nix
examples/
  sdl3-renderer/
    main.c
  tcc-deps/
    main.c
checks/
  default.nix
```

## FHS packaging

`mkFhsPackage` accepts an ordinary derivation:

```nix
mkFhsPackage {
  drv = pkgs.stdenv.mkDerivation { ... };
}
```

Defaults:

- `hostGraphics = true`: GL/Vulkan/DRM/Mesa libraries are left to the host.
- Bundle glibc and the exact `DT_NEEDED` closure of the program.
- Include SONAME symlinks, not whole library directories.
- Remove RPATH/RUNPATH from bundled ELF files.
- Create a sharun launcher and place the real executable in `shared/bin`.

The FHS bundle is validated on a real Fedora-family host with an AMD GPU, both
through Wayland and Xwayland. A headless `xvfb-run` software-Mesa check is kept
for deterministic builds.

## Verification

- `file` every cross output.
- `readelf -d` / `llvm-readelf` for ELF headers, interpreters, and dependencies.
- Windows: inspect PE32+ output.
- Emscripten: inspect `.wasm` and generated JS/HTML.
- FHS: run the actual bundle with a clean environment and confirm the host GPU
  renderer is used and frames are rendered.
- TCC: run the zlib/libpng probe.

## Version control

Use Jujutsu and commit each logical step:

```sh
jj commit -m "message"
```

No Git history rewriting.

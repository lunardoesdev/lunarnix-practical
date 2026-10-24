# lunarnix-practical

A small repository focused on one thing: turning an ordinary Linux Nix
derivation into a portable FHS AppImage.

## Scope

- `mkFhsPackage` wraps any native Linux derivation.
- Output is one executable: `$out/bin/<name>`.
- Inner launcher: pinned **sharun**.
- Outer AppImage runtime: pinned **uruntime** (`URUNTIME_EXTRACT=2`).
- Host graphics stack (GL/EGL/Vulkan/DRM/Mesa) is not bundled by default.

No cross-compilation targets, no Windows/Android/Emscripten/TCC code.

## Layout

```text
flake.nix
default.nix
lib/
  default.nix
  fhs.nix
examples/
  fhs-hello/
  sdl3-renderer/
checks/
  default.nix
```

## FHS packaging details

`lib/fhs.nix`:

1. Stages an AppDir with the real executable under `shared/bin`.
2. Installs sharun as `sharun`, `AppRun`, and the public `bin` entry.
3. Copies glibc and the executable's `DT_NEEDED` closure, excluding host
   graphics libraries when `hostGraphics = true`.
4. Removes RPATH/RUNPATH from bundled ELF files.
5. Packs the AppDir with `mksquashfs`.
6. Prepends uruntime and writes `$out/bin/<name>`.

The result is a single self-extracting AppImage that does not require Nix.

## Verification

- `nix flake check` runs the FHS hello AppImage.
- The SDL3 FHS artifact is checked as a single ELF executable.
- Manual run: `nix build .#sdl3-fhs` then run under Wayland/X11 with OpenGL.

## Version control

Use Jujutsu:

```sh
jj commit -m "message"
```

# lunarnix-practical

Reusable Nix stdenvs and packaging helpers for Windows, FHS Linux, Emscripten,
four Android ABIs, and a Linux tinycc stdenv.

The implementation plan and target details are in [plan.md](plan.md).

## Usage

```sh
nix flake check
nix build .#sdl3-windows
nix build .#sdl3-linux-fhs
nix build .#sdl3-emscripten
nix build .#sdl3-android-aarch64
nix build .#tcc-deps
```

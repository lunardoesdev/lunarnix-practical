# lunarnix-practical

Reusable Nix stdenvs and packaging helpers for Windows (mingwW64), FHS Linux,
Emscripten, four Android ABIs (armv7a, aarch64, i686, x86_64), and a Linux
tinycc stdenv.

All examples use ordinary Nix derivation inputs (`buildInputs`/`nativeBuildInputs`,
`pkg-config`), with no hardcoded `/nix/store` paths.

## Flake usage

Add this repo to your flake inputs (replace the URL with your fork):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lunarnix.url = "git+https://example.com/lunarnix-practical.git";
  };

  outputs = { self, nixpkgs, lunarnix }: { };
}
```

Build the bundled examples:

```sh
nix build .#sdl3-windows
nix build .#sdl3-linux-fhs
nix build .#sdl3-emscripten
nix build .#sdl3-android-aarch64
nix build .#tcc-deps
```

Run checks:

```sh
nix flake check
```

## Using the libraries

### One SDL3 app, many stdenvs

`lib/sdl3-app.nix` builds a single app derivation that works with different stdenvs:

```nix
{ pkgs, lunarnix }:
let
  targets = lunarnix.lib.targets { inherit pkgs; }; # or import
  windows = lunarnix.lib.windows { inherit pkgs targets; };
  android = lunarnix.lib.android { inherit pkgs targets; };
  mkSdl3App = pkgs.callPackage "${lunarnix}/lib/sdl3-app.nix" { src = ./src; };
  sdl3Native = pkgs.callPackage "${lunarnix}/lib/sdl3.nix" { targetPkgs = pkgs; fhs = true; };
in {
  app-native = mkSdl3App { stdenv = pkgs.stdenv; sdl3 = sdl3Native; nativeBuildInputs = [ pkgs.pkg-config ]; };
  app-windows = mkSdl3App { stdenv = windows.stdenv; sdl3 = windows.sdl3; nativeBuildInputs = [ pkgs.pkg-config ]; };
  app-android-aarch64 = mkSdl3App { stdenv = android.aarch64.stdenv; sdl3 = android.aarch64.sdl3; nativeBuildInputs = [ pkgs.pkg-config ]; };
}
```

Or just build directly:

```nix
let
  lunarnix = builtins.getFlake "git+https://example.com/lunarnix-practical.git";
  pkgs = import <nixpkgs> { };
  targets = lunarnix.lib.targets { inherit pkgs; };
  windows = lunarnix.lib.windows { inherit pkgs targets; };
  mkApp = pkgs.callPackage "${lunarnix}/lib/sdl3-app.nix" { src = ./app; };
  sdl3Win = pkgs.callPackage "${lunarnix}/lib/sdl3.nix" { targetPkgs = targets.windows; windows = true; };
in
mkApp { stdenv = windows.stdenv; sdl3 = sdl3Win; nativeBuildInputs = [ pkgs.pkg-config ]; }
```

### FHS portable bundle (single function)

Wrap any derivation in an FHS bundle with host graphics support:

```nix
{ pkgs, lunarnix }:
let
  fhs = lunarnix.lib.fhs { inherit pkgs; };
  myApp = pkgs.stdenv.mkDerivation { /* ... */ };
in
fhs.mkFhsPackage {
  drv = myApp;
  name = "my-app";        # optional
  mainProgram = "my-app"; # optional if drv.meta.mainProgram is set
  hostGraphics = true;    # default: true (keep GL/Vulkan/DRM/Mesa on host)
}
```

The bundle produces sharun-based launchers (`AppRun`, `bin/*`) and places the real
binary in `shared/bin/`. Host graphics libraries are not bundled.

### Emscripten

Build your own SDL3 app for wasm:

```nix
{ pkgs, lunarnix }:
let
  emscripten = lunarnix.lib.emscripten { inherit pkgs; };
  app = import "${lunarnix}/lib/emscripten-app.nix" {
    inherit pkgs;
    sdl3Wasm = emscripten.sdl3;
    src = ./app;
  };
in app
```

Or use `emscriptenStdenv` via the app helper pattern as needed.

### Android (all four ABIs)

```nix
{ pkgs, lunarnix }:
let
  targets = lunarnix.lib.targets { inherit pkgs; };
  android = lunarnix.lib.android { inherit pkgs targets; };
  mkApp = pkgs.callPackage "${lunarnix}/lib/sdl3-app.nix" { src = ./app; };
in {
  armv7a  = mkApp { stdenv = android.armv7a.stdenv; sdl3 = android.armv7a.sdl3; nativeBuildInputs = [ pkgs.pkg-config ]; };
  aarch64 = mkApp { stdenv = android.aarch64.stdenv; sdl3 = android.aarch64.sdl3; nativeBuildInputs = [ pkgs.pkg-config ]; };
  i686    = mkApp { stdenv = android.i686.stdenv; sdl3 = android.i686.sdl3; nativeBuildInputs = [ pkgs.pkg-config ]; };
  x86_64  = mkApp { stdenv = android.x86_64.stdenv; sdl3 = android.x86_64.sdl3; nativeBuildInputs = [ pkgs.pkg-config ]; };
}
```

Android uses NDK 29 / API 35 with `useAndroidPrebuilt = true`. The provided `lib/sdl3.nix`
handles the required overrides for Android.

### TCC stdenv (Linux only)

For C-only code that should build with TinyCC:

```nix
{ pkgs, lunarnix }:
let
  tcc = lunarnix.lib.tcc { inherit pkgs; };
in
tcc.mkDerivation {
  pname = "my-tcc-app";
  version = "1.0.0";
  src = ./app;
  nativeBuildInputs = [ pkgs.pkg-config pkgs.patchelf ];
  buildInputs = [ pkgs.zlib pkgs.libpng ]; # example deps
  hardeningDisable = [ "all" ];
  dontConfigure = true;
  buildPhase = ''
    $CC $(pkg-config --cflags zlib libpng) main.c -o my-tcc-app $(pkg-config --libs zlib libpng)
  '';
  installPhase = ''
    install -Dm755 my-tcc-app "$out/bin/my-tcc-app"
  '';
  postFixup = ''
    patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.zlib pkgs.libpng ]}" "$out/bin/my-tcc-app"
  '';
}
```

## Notes
- FHS bundles rely on the host graphics stack by default; do not bundle Mesa/GL/Vulkan.
- Windows DLLs may be symlinked by mingw stdenv fixup; dereference them if you need relocatable outputs.
- Emscripten uses a plain stdenv + `emcc` to avoid the stricter `buildEmscriptenPackage` check phase.

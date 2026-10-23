{ lib, src }:
{
  stdenv,
  sdl3,
  cc ? "$CC",
  extraFlags ? "",
  pkg-config ? null,
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  preBuild ? "",
  installPhase ? null,
  postInstall ? "",
  postFixup ? "",
  mainProgram ? null,
}:
let
  defaultInstallPhase = ''
    runHook preInstall
    if [ -f sdl3-renderer.exe ]; then
      install -Dm755 sdl3-renderer.exe "$out/bin/sdl3-renderer.exe"
    else
      install -Dm755 sdl3-renderer "$out/bin/sdl3-renderer"
    fi
    ${postInstall}
    runHook postInstall
  '';
in
stdenv.mkDerivation {
  pname = "sdl3-renderer";
  version = "1.0.0";
  inherit src;

  nativeBuildInputs = nativeBuildInputs ++ lib.optional (pkg-config != null) pkg-config;
  buildInputs = [ sdl3 ] ++ buildInputs;

  dontConfigure = true;
  doCheck = false;

  buildPhase = ''
    runHook preBuild
    ${preBuild}
    ${cc} -O2 -Wall -Wextra \
      $(pkg-config --cflags sdl3) main.c -o sdl3-renderer \
      $(pkg-config --libs sdl3) ${extraFlags}
    runHook postBuild
  '';

  installPhase = if installPhase != null then installPhase else defaultInstallPhase;

  inherit postFixup;

  meta.mainProgram =
    if mainProgram != null then mainProgram
    else if stdenv.hostPlatform.isWindows then "sdl3-renderer.exe"
    else "sdl3-renderer";
}

{ pkgs, lunarnix }:

let
  app = pkgs.stdenv.mkDerivation {
    pname = "fhs-hello";
    version = "1.0.0";
    src = ./.;

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      $CC -O2 main.c -o fhs-hello
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 fhs-hello "$out/bin/fhs-hello"
      runHook postInstall
    '';

    meta.mainProgram = "fhs-hello";
  };
in
lunarnix.mkFhsPackage {
  drv = app;
  name = "fhs-hello";
}

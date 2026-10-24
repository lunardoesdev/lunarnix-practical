{ stdenv, rustPlatform }:

rustPlatform.buildRustPackage {
  inherit stdenv;

  pname = "rust-emscripten-lib";
  version = "0.1.0";
  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  doCheck = false;

  installPhase = ''
    mkdir -p "$out/lib"
    cp target/wasm32-unknown-unknown/release/librust_emscripten_lib.a "$out/lib/"
  '';
}

{ stdenv, rustPlatform, zlib, buildPackages }:

rustPlatform.buildRustPackage {
  inherit stdenv;

  pname = "rust-sys-app";
  version = "0.1.0";
  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  buildInputs = [ zlib ];
  nativeBuildInputs = [ buildPackages.pkg-config ];

  # The Rust wasm target uses rust-lld flags (-flavor wasm); point cargo at
  # lld instead of the Emscripten cc driver.
  RUSTFLAGS = "-C linker=${buildPackages.lld}/bin/ld.lld";

  doCheck = false;

  installPhase = ''
    mkdir -p "$out/share/rust-sys-app"
    cp target/wasm32-unknown-unknown/release/rust-sys-app.wasm "$out/share/rust-sys-app/"
  '';
}

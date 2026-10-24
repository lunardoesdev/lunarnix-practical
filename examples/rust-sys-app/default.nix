{ stdenv, rustPlatform, zlib, buildPackages }:

rustPlatform.buildRustPackage {
  inherit stdenv;

  pname = "rust-sys-app";
  version = "0.1.0";
  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  buildInputs = [ zlib ];
  nativeBuildInputs = [ buildPackages.pkg-config ];

  doCheck = false;

  installPhase = ''
    mkdir -p "$out/share/rust-sys-app"
    cp target/wasm32-unknown-unknown/release/rust-sys-app.wasm "$out/share/rust-sys-app/"
  '';
}

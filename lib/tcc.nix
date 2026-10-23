{ pkgs }:

let
  inherit (pkgs) lib;

  # `pkgs.tinycc` resolves to the `dev` output; the compiler binary lives in
  # `out` and libtcc plus its runtime objects live in `lib`.
  tcc = pkgs.tinycc.out;
  tccLib = pkgs.tinycc.lib;

  tccWrapper = pkgs.runCommand "tcc-stdenv-wrapper-${tcc.version}" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p "$out/bin" "$out/nix-support"

    cat > "$out/bin/tcc" <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu

    # TCC needs its own runtime objects and headers.
    args="-B${tccLib}/lib/tcc"

    # Consume the dependency flags that stdenv derives from buildInputs.
    for flag in ''${NIX_CFLAGS_COMPILE:-}; do
      case "$flag" in
        -I*|-D*|-U*) args="$args $flag" ;;
      esac
    done
    for flag in ''${NIX_LDFLAGS:-}; do
      case "$flag" in
        -L*) args="$args $flag" ;;
      esac
    done

    exec "${tcc}/bin/tcc" $args "$@"
    EOF
    chmod +x "$out/bin/tcc"

    cat > "$out/bin/tcc-ar" <<'EOF'
    #!${pkgs.runtimeShell}
    exec "${tcc}/bin/tcc" -ar "$@"
    EOF
    chmod +x "$out/bin/tcc-ar"

    cat > "$out/bin/tcc-ranlib" <<'EOF'
    #!${pkgs.runtimeShell}
    exit 0
    EOF
    chmod +x "$out/bin/tcc-ranlib"

    ln -s tcc "$out/bin/cc"
    ln -s tcc-ar "$out/bin/ar"
    ln -s tcc-ranlib "$out/bin/ranlib"

    cat > "$out/nix-support/setup-hook" <<EOF
    export CC="$out/bin/tcc"
    export AR="$out/bin/tcc-ar"
    export RANLIB="$out/bin/tcc-ranlib"
    export LD="$out/bin/tcc"
    EOF
  '';

  tccStdenv = pkgs.stdenv.override {
    cc = tccWrapper;
    # The stock stdenv allow-list is built for the default toolchain. A TCC
    # stdenv legitimately refers to the TCC binary and its runtime library.
    allowedRequisites = null;
  };
in
{
  inherit tcc tccLib tccWrapper tccStdenv;
  mkDerivation = tccStdenv.mkDerivation;
}

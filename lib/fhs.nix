{ pkgs }:

let
  inherit (pkgs) lib;

  sharun = pkgs.fetchurl {
    url = "https://github.com/pkgforge-dev/Anylinux-sharun/releases/download/3.5.1/sharun-x86_64";
    hash = "sha256-XbkqdJL4sb75wrplM0ZDaot8xBMSZxWlCZPKBdl0ZbQ=";
  };

  uruntime = pkgs.fetchurl {
    url = "https://github.com/VHSgunzo/uruntime/releases/download/v0.8.1/uruntime-appimage-squashfs-lite-x86_64";
    hash = "sha256-MsYCShT/N1dJ7jvtMzDBWGpt0r/t27186swFOuwrJ6M=";
  };

  hostGraphicsPattern = lib.concatMapStringsSep "|" (name: "${name}*") [
    "libGL.so"
    "libEGL.so"
    "libGLX.so"
    "libGLdispatch.so"
    "libOpenGL.so"
    "libGLESv1_CM.so"
    "libGLESv2.so"
    "libgbm.so"
    "libvulkan.so"
    "libdrm.so"
    "libLLVM.so"
    "libgallium"
    "libglapi.so"
    "libxatracker.so"
    "libvdpau.so"
    "libva.so"
  ];
in
{
  mkFhsPackage =
    {
      drv,
      mainProgram ? drv.meta.mainProgram or (drv.pname or "app"),
      hostGraphics ? true,
      checkCommand ? "",
      name ? mainProgram,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "${name}-fhs-portable";
      version = "1";

      nativeBuildInputs = with pkgs; [
        bash
        coreutils
        findutils
        glibc.bin
        gnugrep
        gnused
        patchelf
        squashfsTools
      ];

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;

      installPhase = ''
        set -eu

        bin="${lib.getExe' drv mainProgram}"
        mkdir -p "$out/bin" "$out/shared/bin" "$out/lib"

        cp -L "$bin" "$out/shared/bin/${mainProgram}"
        cp -L ${sharun} "$out/sharun"
        chmod +x "$out/sharun"
        ln "$out/sharun" "$out/AppRun"
        ln "$out/sharun" "$out/bin/${mainProgram}"

        # Bundle glibc, including its loader and NSS modules.
        cp -L ${pkgs.glibc}/lib/*.so* "$out/lib/"
        chmod -R u+w "$out/lib"

        # Resolve the executable's exact DT_NEEDED closure. The left-hand name
        # is the SONAME the loader will ask for; materialise that name directly
        # so SONAME aliases remain usable without shipping whole store dirs.
        if ${pkgs.glibc.bin}/bin/ldd "$out/shared/bin/${mainProgram}" | grep -q 'not found'; then
          echo "ERROR: unresolved runtime dependency" >&2
          ${pkgs.glibc.bin}/bin/ldd "$out/shared/bin/${mainProgram}" >&2 || true
          exit 1
        fi

        ${pkgs.glibc.bin}/bin/ldd "$out/shared/bin/${mainProgram}" | awk '
          $1 !~ /^\// && $2 == "=>" && $3 ~ /^\// { print $1, $3 }
          $1 ~ /^\// { n=$1; sub(/^.*\//, "", n); print n, $1 }
        ' | while read -r soname path; do
          [ -e "$path" ] || continue
          case "$soname" in
            ${if hostGraphics then hostGraphicsPattern else "__never_matches__"})
              echo "leaving ''${soname} to the host graphics stack"
              continue
              ;;
          esac
          cp -Lf --no-preserve=mode,ownership "$path" "$out/lib/$soname"
        done

        test -f "$out/lib/ld-linux-x86-64.so.2" || {
          echo "ERROR: missing dynamic loader" >&2
          exit 1
        }

        chmod -R u+w "$out/lib" "$out/shared/bin"
        for f in "$out"/lib/*.so* "$out/shared/bin/${mainProgram}"; do
          [ -f "$f" ] || continue
          [ -L "$f" ] && continue
          case "$(basename "$f")" in
            ld-*) continue ;;
          esac
          if [ "$(dd if="$f" bs=1 count=4 2>/dev/null)" = "$(printf '\177ELF')" ]; then
            patchelf --remove-rpath "$f" || true
          fi
        done

        : > "$out/.env"
        cat > "$out/${name}.desktop" <<EOF
        [Desktop Entry]
        Type=Application
        Name=${name}
        Exec=${mainProgram}
        Terminal=true
        Categories=Development;
        EOF

        echo "bundled $(find "$out/lib" -maxdepth 1 -type f | wc -l) libraries"

        # Make an AppImage from this AppDir: sharun remains the AppDir's
        # launcher, and uruntime is the outer self-extracting AppImage runtime.
        mksquashfs "$out" "$TMPDIR/${name}.squashfs" \
          -root-owned -noappend -comp zstd -quiet
        cp ${uruntime} "$TMPDIR/runtime"
        chmod u+w "$TMPDIR/runtime"
        sed -i 's/URUNTIME_EXTRACT=[0-9]/URUNTIME_EXTRACT=2/' "$TMPDIR/runtime"
        grep -a -q 'URUNTIME_EXTRACT=2' "$TMPDIR/runtime"
        cat "$TMPDIR/runtime" "$TMPDIR/${name}.squashfs" \
          > "$out/${name}-x86_64.AppImage"
        chmod +x "$out/${name}-x86_64.AppImage"
      '';

      doInstallCheck = checkCommand != "";
      installCheckPhase = ''
        runHook preInstallCheck
        ${checkCommand}
        runHook postInstallCheck
      '';

      meta.mainProgram = mainProgram;
    };

}

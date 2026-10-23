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

        appdir="$TMPDIR/AppDir"
        bin="${lib.getExe' drv mainProgram}"
        mkdir -p "$appdir/bin" "$appdir/shared/bin" "$appdir/lib"

        cp -L "$bin" "$appdir/shared/bin/${mainProgram}"
        cp -L ${sharun} "$appdir/sharun"
        chmod +x "$appdir/sharun"
        ln "$appdir/sharun" "$appdir/AppRun"
        ln "$appdir/sharun" "$appdir/bin/${mainProgram}"

        # Bundle glibc, including its loader and NSS modules.
        cp -L ${pkgs.glibc}/lib/*.so* "$appdir/lib/"
        chmod -R u+w "$appdir/lib"

        # Resolve the executable's exact DT_NEEDED closure. The left-hand name
        # is the SONAME the loader will ask for; materialise that name directly
        # so SONAME aliases remain usable without shipping whole store dirs.
        if ${pkgs.glibc.bin}/bin/ldd "$appdir/shared/bin/${mainProgram}" | grep -q 'not found'; then
          echo "ERROR: unresolved runtime dependency" >&2
          ${pkgs.glibc.bin}/bin/ldd "$appdir/shared/bin/${mainProgram}" >&2 || true
          exit 1
        fi

        ${pkgs.glibc.bin}/bin/ldd "$appdir/shared/bin/${mainProgram}" | awk '
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
          cp -Lf --no-preserve=mode,ownership "$path" "$appdir/lib/$soname"
        done

        test -f "$appdir/lib/ld-linux-x86-64.so.2" || {
          echo "ERROR: missing dynamic loader" >&2
          exit 1
        }

        chmod -R u+w "$appdir/lib" "$appdir/shared/bin"
        for f in "$appdir"/lib/*.so* "$appdir/shared/bin/${mainProgram}"; do
          [ -f "$f" ] || continue
          [ -L "$f" ] && continue
          case "$(basename "$f")" in
            ld-*) continue ;;
          esac
          if [ "$(dd if="$f" bs=1 count=4 2>/dev/null)" = "$(printf '\177ELF')" ]; then
            patchelf --remove-rpath "$f" || true
          fi
        done

        : > "$appdir/.env"
        cat > "$appdir/${name}.desktop" <<EOF
        [Desktop Entry]
        Type=Application
        Name=${name}
        Exec=${mainProgram}
        Terminal=true
        Categories=Development;
        EOF

        echo "bundled $(find "$appdir/lib" -maxdepth 1 -type f | wc -l) libraries"

        # sharun launches the app inside the SquashFS AppDir; uruntime prefixes
        # the AppDir image to produce the one-file AppImage package output.
        mksquashfs "$appdir" "$TMPDIR/${name}.squashfs" \
          -root-owned -noappend -comp zstd -quiet
        cp ${uruntime} "$TMPDIR/runtime"
        chmod u+w "$TMPDIR/runtime"
        sed -i 's/URUNTIME_EXTRACT=[0-9]/URUNTIME_EXTRACT=2/' "$TMPDIR/runtime"
        grep -a -q 'URUNTIME_EXTRACT=2' "$TMPDIR/runtime"
        mkdir -p "$out/bin"
        cat "$TMPDIR/runtime" "$TMPDIR/${name}.squashfs" \
          > "$out/bin/${name}"
        chmod +x "$out/bin/${name}"
      '';

      doInstallCheck = checkCommand != "";
      installCheckPhase = ''
        runHook preInstallCheck
        ${checkCommand}
        runHook postInstallCheck
      '';

      meta.mainProgram = name;
    };

}

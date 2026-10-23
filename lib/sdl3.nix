{ pkgs, targetPkgs, android ? false, fhs ? false, windows ? false }:

let
  inherit (pkgs) lib;

  # Do not start from `targetPkgs.sdl3`: on Android the stock package fails its
  # own `ibusSupport -> dbusSupport` assertion before `.override` is reachable.
  # Calling the nixpkgs expression directly lets us pass the platform switches
  # that Android needs.
  packageArgs =
    if android then {
      ibusSupport = false;
      dbusSupport = false;
      traySupport = false;
      libusbSupport = false;
      vulkanSupport = false;
      openglSupport = false;
    } else if fhs || windows then {
      vulkanSupport = false;
    } else { };

  base = targetPkgs.callPackage (targetPkgs.path + "/pkgs/by-name/sd/sdl3/package.nix") packageArgs;
in
base.overrideAttrs (old: {
  doCheck = false;

  # Bionic's fortified poll()/ppoll64() wrappers do not compile with the NDK 29
  # clang precompiled header when _FORTIFY_SOURCE is set by stdenv hardening.
  hardeningDisable = (old.hardeningDisable or [ ]) ++ lib.optional android "fortify";

  # Turning SDL_INSTALL_TESTS off means the `installedTests` output is never
  # populated; drop it so the derivation does not expect an empty output.
  outputs = builtins.filter (o: o != "installedTests") (old.outputs or [ "out" ]);

  cmakeFlags =
    lib.filter
      (flag:
        !(lib.hasPrefix "-DSDL_TESTS=" flag)
        && !(lib.hasPrefix "-DSDL_INSTALL_TESTS=" flag))
      (old.cmakeFlags or [ ])
    ++ [
      "-DSDL_TESTS=OFF"
      "-DSDL_INSTALL_TESTS=OFF"
    ]
    ++ lib.optionals android [
      "-DANDROID=ON"
      "-DSDL_ANDROID_JAR=OFF"
      "-DSDL_OPENGLES=ON"
      "-DSDL_UNIX_CONSOLE_BUILD=ON"
    ];
})

{ pkgs }:

let
  inherit (pkgs) lib;

  importCross = crossSystem:
    import pkgs.path {
      localSystem = pkgs.stdenv.hostPlatform.system;
      inherit crossSystem;
      config = {
        allowUnfree = true;
      };
    };

  androidCross = config: {
    inherit config;
    androidSdkVersion = "35";
    androidNdkVersion = "29";
    useAndroidPrebuilt = true;
  };

  mkAndroid = config: importCross (androidCross config);
in
{
  windows = importCross lib.systems.examples.mingwW64;

  android = {
    armv7a = mkAndroid "armv7a-unknown-linux-androideabi";
    aarch64 = mkAndroid "aarch64-unknown-linux-android";
    i686 = mkAndroid "i686-unknown-linux-android";
    x86_64 = mkAndroid "x86_64-unknown-linux-android";
  };
}

{ pkgs }:

{
  x86_64-linux = pkgs;
  x86_64-windows = pkgs.pkgsCross.mingwW64;

  android-armv7a = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;
    crossSystem = {
      config = "armv7a-unknown-linux-androideabi";
      androidSdkVersion = "35";
      androidNdkVersion = "29";
      useAndroidPrebuilt = true;
    };
    config.allowUnfree = true;
  };

  android-aarch64 = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;
    crossSystem = {
      config = "aarch64-unknown-linux-android";
      androidSdkVersion = "35";
      androidNdkVersion = "29";
      useAndroidPrebuilt = true;
    };
    config.allowUnfree = true;
  };

  android-i686 = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;
    crossSystem = {
      config = "i686-unknown-linux-android";
      androidSdkVersion = "35";
      androidNdkVersion = "29";
      useAndroidPrebuilt = true;
    };
    config.allowUnfree = true;
  };

  android-x86_64 = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;
    crossSystem = {
      config = "x86_64-unknown-linux-android";
      androidSdkVersion = "35";
      androidNdkVersion = "29";
      useAndroidPrebuilt = true;
    };
    config.allowUnfree = true;
  };

}

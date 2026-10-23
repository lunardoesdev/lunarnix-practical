{
  description = "Reusable Nix stdenvs for Windows, FHS Linux, Emscripten, Android, and tinycc";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
      let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      lunarnix = import ./lib { inherit pkgs; };
      packages = import ./packages.nix { inherit pkgs lunarnix; };
    in
    {
      # These are complete nixpkgs package sets, each with its target stdenv.
      x86_64-linux = lunarnix.x86_64-linux;
      x86_64-windows = lunarnix.x86_64-windows;
      android-armv7a = lunarnix.android-armv7a;
      android-aarch64 = lunarnix.android-aarch64;
      android-i686 = lunarnix.android-i686;
      android-x86_64 = lunarnix.android-x86_64;
      inherit (lunarnix) emscriptenStdenv emscriptenSdl3 tccStdenv;

      inherit (lunarnix) mkFhsPackage;
      lib = lunarnix;

      packages.${system} = packages // {
        default = packages.sdl3-linux-fhs;
      };

      checks.${system} = import ./checks {
        inherit pkgs packages;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          binutils
          file
          gnumake
          jq
          nix
          pkg-config
        ];
      };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}

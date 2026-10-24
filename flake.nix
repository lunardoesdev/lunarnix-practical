{
  description = "FHS portable AppImage bundles with sharun and uruntime";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      lunarnix = import ./lib { inherit pkgs; };
      packages = import ./packages.nix { inherit pkgs lunarnix; };
    in
    {
      # The FHS helper plus the Emscripten cross environment.
      inherit (lunarnix) mkFhsPackage emscripten;
      lib = lunarnix;

      packages.${system} = packages // {
        default = packages.fhs-hello;
      };

      checks.${system} = import ./checks {
        inherit pkgs packages;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          binutils
          file
          patchelf
          squashfsTools
        ];
      };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}

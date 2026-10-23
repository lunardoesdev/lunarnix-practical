{
  description = "Practical Nix stdenvs for Windows, FHS Linux, Emscripten, Android, and tinycc";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];

      each = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      packagesFor = pkgs: import ./packages.nix { inherit pkgs; };
    in
    {
      packages = each (pkgs: packagesFor pkgs // {
        default = (packagesFor pkgs).sdl3-linux-fhs;
      });

      checks = each (pkgs: import ./checks {
        inherit pkgs;
        packages = packagesFor pkgs;
      });

      devShells = each (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            binutils
            file
            gnumake
            jq
            nix
            pkg-config
          ];
        };
      });

      formatter = each (pkgs: pkgs.nixpkgs-fmt);
    };
}

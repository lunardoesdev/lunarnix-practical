{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

import ./lib { inherit pkgs; }

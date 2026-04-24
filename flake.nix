{
  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-patcher.url = "github:yuko1101/git-patcher";
    upstream = {
      url = ./upstream;
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    upstream,
    rust-overlay,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };
        custom-rust-bin = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            inputs.git-patcher.packages.${system}.default
            custom-rust-bin
          ];

          GIT_PATCHER_CONFIG = ./patcher.toml;
        };

        packages.src = inputs.git-patcher.lib.applyPatches {
          inherit upstream pkgs;
          src = self;
        };
      }
    );
}

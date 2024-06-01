{
  description = "Keymaster";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    gitignore = {
      url = "github:hercules-ci/gitignore";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cachix.cachix.org"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "aarch64-darwin.cachix.org-1:mEz8A1jcJveehs/ZbZUEjXZ65Aukk9bg2kmb0zL9XDA="
    ];
  };

  outputs =
    {
      pre-commit-hooks,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pre-commit-check = pkgs.callPackage ./pre-commit-check.nix {
          inherit pkgs pre-commit-hooks system;
        };
      in
      with pkgs;
      {
        checks = {
          inherit pre-commit-check;
        };

        formatter = nixfmt-rfc-style;
        devShells = {
          default = mkShell.override { inherit (swift) stdenv; } {
            nativeBuildInputs = with pkgs; [
              swift
              swiftpm
              xcodebuild
            ];

            shellHook =
              pre-commit-check.shellHook
              + ''
                export PS1="\n\[\033[01;32m\]\u $\[\033[00m\]\[\033[01;36m\] \w >\[\033[00m\] "
              '';
          };
          install-hooks = mkShell.override { stdenv = stdenvNoCC; } {
            inherit system;
            shellHook =
              let
                inherit (pre-commit-check) shellHook;
              in
              ''
                ${shellHook}
                echo Done!
                exit
              '';
          };
        };
      }
    );
}

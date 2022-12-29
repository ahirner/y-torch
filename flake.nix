{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    {
      # Nixpkgs overlay providing the application
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev: {
          y-torch = prev.poetry2nix.mkPoetryApplication {
            projectDir = ./.;
          };
        })
      ];
    }
    // (flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlay];
        config.allowUnfree = true;
      };

      customOverrides = self: super: {};
      env =
        pkgs.poetry2nix.mkPoetryEnv
        {
          projectDir = ./.;
          preferWheels = true;
          overrides = pkgs.poetry2nix.overrides.withDefaults customOverrides;
        };
    in {
      apps.default = {
        program = "${pkgs.y-torch}/bin/y-torch";
        type = "app";
      };

      packages.default = pkgs.poetry;

      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          poetry
          env
        ];
      };
    }));
}

{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix = {
    # includes torch recursive fix from: github:cpcloud/poetry2nix/rollup
    url = "github:ahirner/poetry2nix/fix/wheel-recursion";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    {
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: pkgs: rec {
          # cuda surgery: https://github.com/nix-community/poetry2nix/issues/850#issuecomment-1356844427
          customOverrides = self: super: {
            nvidia-cudnn-cu11 = super.nvidia-cudnn-cu11.overridePythonAttrs (attrs: {
              nativeBuildInputs = attrs.nativeBuildInputs or [] ++ [pkgs.autoPatchelfHook];
              preFixup = ''
                addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
              '';
              postFixup = ''
                rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
              '';
              propagatedBuildInputs =
                attrs.propagatedBuildInputs
                or []
                ++ [
                  self.nvidia-cublas-cu11
                ];
            });
            nvidia-cuda-nvrtc-cu11 = super.nvidia-cuda-nvrtc-cu11.overridePythonAttrs (_: {
              postFixup = ''
                rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
              '';
            });
            torch = super.torch.overridePythonAttrs (attrs: {
              nativeBuildInputs =
                attrs.nativeBuildInputs
                or []
                ++ [
                  pkgs.autoPatchelfHook
                  pkgs.cudaPackages.autoAddOpenGLRunpathHook
                ];
              buildInputs =
                attrs.buildInputs
                or []
                ++ [
                  self.nvidia-cudnn-cu11
                  self.nvidia-cuda-nvrtc-cu11
                  self.nvidia-cuda-runtime-cu11
                ];
              postInstall = ''
                addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
                addAutoPatchelfSearchPath "${self.nvidia-cudnn-cu11}/${self.python.sitePackages}/nvidia/cudnn/lib"
                addAutoPatchelfSearchPath "${self.nvidia-cuda-nvrtc-cu11}/${self.python.sitePackages}/nvidia/cuda_nvrtc/lib"
              '';
            });
          };

          # application
          y-torch = pkgs.poetry2nix.mkPoetryApplication {
            projectDir = ./.;
            preferWheels = true;
            overrides = pkgs.poetry2nix.overrides.withDefaults customOverrides;
          };

          # environment
          env =
            pkgs.poetry2nix.mkPoetryEnv
            {
              projectDir = ./.;
              preferWheels = true;
              overrides = pkgs.poetry2nix.overrides.withDefaults customOverrides;
            };
        })
      ];
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlay];
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
    });
}

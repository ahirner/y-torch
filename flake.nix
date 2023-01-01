{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [poetry2nix.overlay];
          config.allowUnfree = true;
        };

        # cuda surgery: https://github.com/cpcloud/torch-p2nix
        customOverrides = self: super: {
          # can be removed after https://github.com/nix-community/poetry2nix/issues/850
          wheel = super.wheel.override {preferWheel = false;};

          nvidia-cudnn-cu11 = super.nvidia-cudnn-cu11.overridePythonAttrs (attrs: {
            nativeBuildInputs = attrs.nativeBuildInputs or [] ++ [pkgs.autoPatchelfHook];
            propagatedBuildInputs =
              attrs.propagatedBuildInputs
              or []
              ++ [
                self.nvidia-cublas-cu11
                self.pkgs.cudaPackages.cudnn_8_5_0
              ];

            preFixup = ''
              addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
            '';
            postFixup = ''
              rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
            '';
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

        y-torch = pkgs.poetry2nix.mkPoetryApplication {
          projectDir = ./.;
          preferWheels = true;
          overrides = [customOverrides pkgs.poetry2nix.defaultPoetryOverrides];
          python = pkgs.python310;
        };
        env = pkgs.poetry2nix.mkPoetryEnv {
          projectDir = ./.;
          preferWheels = true;
          overrides = [customOverrides pkgs.poetry2nix.defaultPoetryOverrides];
          python = pkgs.python310;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [pkgs.poetry env];
        };
        packages.env = env;
        packages.default = y-torch;
        packages.poetry = pkgs.poetry;
      }
    );
}

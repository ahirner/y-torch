# y-torch

`nix` based ML development environment.

## Develop

Update `flake.lock`:

```shell
nix flake update
```

Update `poetry.lock`:

```shell
nix shell -c poetry update
```

Run:

```shell
git add .
nix run
```

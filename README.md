# y-torch

`nix` based ML development environment.

## Develop

Update `flake.lock`:

```shell
nix flake update
```

Update `poetry.lock`:

```shell
nix shell .#poetry -c poetry lock
```

Run:

```shell
git add .
nix run
```

Develop:

```shell
nix develop
y-torch
```

# moon-flake

Nix flake for [moon](https://moonrepo.dev/).

## Packages

- `moon-bin` (default) — prebuilt binary from GitHub releases
- `moon` — built from source

## Usage

flake.nix:

```nix
{
  inputs.moon.url = "github:socksy/moon-flake";

  outputs = { moon, ... }: {
    # moon.packages.${system}.default
  };
}
```

### With devenv

devenv.yaml:

```yaml
inputs:
  moon:
    url: github:socksy/moon-flake
```

devenv.nix:

```nix
{ pkgs, inputs, ... }: {
  packages = [ inputs.moon.packages.${pkgs.system}.default ];
}
```

(As long as `pkgs.system` is one-of `x86_64-linux`, `aarch64-linux` or `aarch64-darwin`)

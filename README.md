# Orca Slicer NixOS Flake

A small package-only flake for Orca Slicer on x86_64-linux.

## Why this exists

If you want a newer Orca Slicer release than the one currently available in the main NixOS package set, you usually have to wait until upstream packaging catches up.

This repository exists to avoid that wait:

- track Orca Slicer releases independently from the main NixOS package lifecycle
- keep update logic local and easy to rerun
- let you pin or update Orca Slicer on your own schedule

## What the flake provides

- packages.x86_64-linux.orca-slicer for the package
- packages.x86_64-linux.default as the default package
- overlays.default for adding orca-slicer to pkgs

The package is based on the nixpkgs Orca Slicer derivation, with versioning and source hash managed locally in this flake.

## Installation example

### 1. Clone this repository locally

```bash
git clone <your-fork-or-local-copy> ~/src/orca-slicer-nixos-flake
```

### 2. Add it to your main flake as a local input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    orca-slicer = {
      url = "path:/home/your-user/src/orca-slicer-nixos-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### 3. Add the package to your configuration

For NixOS:

```nix
{
  environment.systemPackages = [
    inputs.orca-slicer.packages.x86_64-linux.orca-slicer
  ];
}
```

For Home Manager:

```nix
{
  home.packages = [
    inputs.orca-slicer.packages.x86_64-linux.orca-slicer
  ];
}
```

If you prefer overlays instead of referencing the package directly:

```nix
{
  nixpkgs.overlays = [ inputs.orca-slicer.overlays.default ];

  environment.systemPackages = with pkgs; [
    orca-slicer
  ];
}
```

## Updating

The update script:

- fetches the latest versioned GitHub release by default, including pre-releases
- ignores non-version utility tags such as nightly aliases
- recalculates srcHash
- updates flake.nix
- verifies that the package still builds unless disabled

Run the default update flow:

```bash
./update-orca-slicer.sh
```

Use only stable releases:

```bash
ORCA_RELEASE_CHANNEL=stable ./update-orca-slicer.sh
```

Skip build verification if you only want to refresh version and hash:

```bash
ORCA_SKIP_BUILD=1 ./update-orca-slicer.sh
```

Requirements:

- curl
- jq
- nix
- nix-prefetch-url

## Build notes

Orca Slicer is a heavy source build, so update verification can take noticeable time.

You can test locally with:

```bash
nix build .#orca-slicer -L
```

## Packaging notes

This flake includes local packaging adjustments on top of nixpkgs, including patches under patches/ and dependency tweaks in package.nix.

## Repository contents

```text
.
├── flake.nix
├── flake.lock
├── package.nix
├── update-orca-slicer.sh
├── README.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── LICENSE
└── patches/
```

## License

The repository contents and packaging code are licensed under the MIT License. See LICENSE.

The packaged Orca Slicer software itself follows its upstream license terms.

## Contributing

See CONTRIBUTING.md for contribution and verification guidance.

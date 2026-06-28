# AGENTS.md

## What This Repo Builds

- The flake packages Intel CSME System Tools v16 Linux binaries from the upstream release zip, not from the upstream Git repo.
- Supported system is only `x86_64-linux`.
- Exposed apps and wrapped binaries are `fpt`, `fwupdlcl`, `meinfo`, `memanuf`, `meu`, and `mfit`.
- Wrappers run through `steam-run`, so unfree nixpkgs config is required inside the flake for `steam`, `steam-run`, and `steam-unwrapped`.

## Important Layout Assumption

- The build expects the fetched zip to contain a double-nested directory layout:
  - `CSME System Tools v16.0 r8/CSME System Tools v16.0 r8/...`
- This is enforced intentionally. If that layout changes, the build should fail rather than silently guessing.

## Exact Commands

- Evaluate the flake: `nix flake check`
- Build the package: `nix build .#intel-cs-tools`
- Run one wrapped tool after build: `./result/bin/meinfo --help`
- Enter the dev shell with hooks and package on `PATH`: `nix develop`
- Run formatting and lint hooks: `nix develop -c pre-commit run --all-files`

## Pre-commit

- Hooks are defined through `git-hooks.nix` in `flake.nix`.
- Enabled hooks are only `alejandra` and `deadnix`.
- The generated `.pre-commit-config.yaml` is ignored and should not be committed.

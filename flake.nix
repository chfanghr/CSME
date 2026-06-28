{
  description = "Intel CSME System Tools v16 wrappers";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.git-hooks-nix.flakeModule];

      systems = ["x86_64-linux"];

      perSystem = {
        config,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "steam"
              "steam-run"
              "steam-unwrapped"
            ];
        };

        lib = pkgs.lib;
        csmeV16Dir = "CSME System Tools v16.0 r8";
        csmeV16Root = "${csmeV16Dir}/${csmeV16Dir}";
        csmeV16Src = pkgs.fetchzip {
          url = "https://github.com/CE1CECL/IntelCSTools/releases/download/v1.0.0/CSME.System.Tools.v16.0.r8.zip";
          hash = "sha256-d4Ay7SzOBjFAsBLpDJJGUX2W78yTabMSPPRNsGfYKsU=";
          stripRoot = false;
        };

        tools = {
          fpt = {
            description = "Intel Flash Programming Tool";
            sourcePath = "Flash Programming Tool/LINUX64/FPT";
          };
          fwupdlcl = {
            description = "Intel firmware update utility";
            sourcePath = "FWUpdate/LINUX64/FWUpdLcl";
          };
          meinfo = {
            description = "Intel Management Engine info utility";
            sourcePath = "MEInfo/LINUX64/MEInfo";
          };
          memanuf = {
            description = "Intel Management Engine manufacturing utility";
            sourcePath = "MEManuf/LINUX64/MEManuf";
          };
          meu = {
            description = "Intel manifest extension utility";
            sourcePath = "Manifest Extension Utility/LINUX64/meu";
          };
          mfit = {
            description = "Intel modular flash image tool";
            sourcePath = "Modular Flash Image Tool/LINUX64/mfit";
          };
        };

        package = pkgs.stdenvNoCC.mkDerivation {
          pname = "intel-cs-tools";
          version = "16.0-r8";
          src = csmeV16Src;

          dontUnpack = true;
          nativeBuildInputs = [pkgs.makeWrapper];

          installPhase = let
            mkInstall = command: tool: ''
              install -Dm755 "$src/${csmeV16Root}/${tool.sourcePath}" "$out/share/intel-cs-tools/${command}"
              makeWrapper ${pkgs.steam-run}/bin/steam-run "$out/bin/${command}" \
                --add-flags "$out/share/intel-cs-tools/${command}"
            '';
          in ''
            runHook preInstall

            mkdir -p "$out/bin" "$out/share/intel-cs-tools"

            [ -d "$src/${csmeV16Dir}" ]
            [ -d "$src/${csmeV16Root}" ]

            ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkInstall tools)}

            runHook postInstall
          '';

          meta = {
            description = "Wrapped Intel CSME System Tools v16 Linux64 binaries";
            homepage = "https://github.com/CE1CECL/IntelCSTools";
            platforms = ["x86_64-linux"];
            sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
          };
        };
      in {
        _module.args.pkgs = pkgs;

        pre-commit = {
          settings.hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
          };
        };

        packages = {
          default = package;
          intel-cs-tools = package;
        };

        apps =
          lib.mapAttrs (name: tool: {
            meta.description = tool.description;
            type = "app";
            program = "${package}/bin/${name}";
          })
          tools;

        devShells.default = config.pre-commit.devShell.overrideAttrs (old: {
          buildInputs = (old.buildInputs or []) ++ [package];
        });
      };
    };
}

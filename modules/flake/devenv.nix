{ lib, inputs, ... }: let
  superInputs = inputs;
in { flake-parts-lib, lib, inputs, ... }: let
  devenv = inputs.devenv or superInputs.devenv;
in {
  imports = [
    devenv.flakeModule
  ];
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, system, ... }: let
    superPkgs = pkgs;
    pkgsPath = builtins.toPath (inputs.nixpkgs or superInputs.nixpkgs);
    isConfig = x: builtins.isAttrs x || builtins.isFunction x;
    optCall = f: x: if builtins.isFunction f then f x else f;
  in {
    imports = [
      ({ config, ... }: {
        config = lib.mkIf (config.devenv.shells != {}) {
          devShells = let
            # for lsp / completions
            shells = lib.mapAttrs (name: devenv: devenv.shell // { 
              config = config.devenv.shells.${name};
              inherit (shells.${name}.config.outputs) options;
              inherit (shells.${name}.options._module.args.value) pkgs;
            }) config.devenv.shells;
          in lib.mkForce shells;
        };
      })
    ];
    config.devenv.modules = [
      devenv.flakeModules.readDevenvRoot
      { _module.args = { systemConfig = config; inherit system; }; }
      ({ config, options, ... }: {
        outputs = { inherit options config; };  
      })
      ({ config, pkgs, system, systemConfig, ... }: let
        mergeConfig = lhs_: rhs_:
        let
          lhs = optCall lhs_ { inherit pkgs; };
          rhs = optCall rhs_ { inherit pkgs; };
        in lhs // rhs // lib.optionalAttrs (lhs ? packageOverrides) {
          packageOverrides = pkgs:
            optCall lhs.packageOverrides pkgs
            // optCall (lib.attrByPath [ "packageOverrides" ] { } rhs) pkgs;
        } // lib.optionalAttrs (lhs ? perlPackageOverrides) {
          perlPackageOverrides = pkgs:
            optCall lhs.perlPackageOverrides pkgs
            // optCall (lib.attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
        };
        configType = lib.mkOptionType {
          name = "nixpkgs-config";
          description = "nixpkgs config";
          check = x:
            let traceXIfNot = c: if c x then true else lib.traceSeqN 1 x false;
            in traceXIfNot isConfig;
          merge = args: lib.fold (def: mergeConfig def.value) { };
        };

        overlayType = lib.mkOptionType {
          name = "nixpkgs-overlay";
          description = "nixpkgs overlay";
          check = lib.isFunction;
          merge = lib.mergeOneOption;
        };

        _pkgs = import pkgsPath (lib.filterAttrs (n: v: v != null) (config.nixpkgs // {
          config = let
            super = systemConfig.nixpkgs.config or null;
            curre = config.nixpkgs.config or null;
          in
            if isNull super && !(isNull curre) then
              super
            else if !(isNull super) && isNull curre then
              curre
            else if !(isNull curre) && !(isNull curre) then
              super // curre
            else null;
        }));
        finalPkgs = superPkgs.appendOverlays config.nixpkgs.overlays;
        cfg = config.nixpkgs;
      in {
        options.nixpkgs = {
          config = lib.mkOption {
            default = null;
            example = { allowBroken = true; };
            type = lib.types.nullOr configType;
            description = ''
              The configuration of the Nix Packages collection. (For
              details, see the Nixpkgs documentation.) It allows you to set
              package configuration options.

              If `null`, then configuration is taken from
              the fallback location, for example,
              {file}`~/.config/nixpkgs/config.nix`.

              Note, this option will not apply outside your Home Manager
              configuration like when installing manually through
              {command}`nix-env`. If you want to apply it both
              inside and outside Home Manager you can put it in a separate
              file and include something like

              ```nix
                nixpkgs.config = import ./nixpkgs-config.nix;
                xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
              ```

              in your Home Manager configuration.
            '';
          };

          overlays = lib.mkOption {
            default = [];
            example = lib.literalExpression ''
              [
                (final: prev: {
                  openssh = prev.openssh.override {
                    hpnSupport = true;
                    withKerberos = true;
                    kerberos = final.libkrb5;
                  };
                })
              ]
            '';
            type = lib.types.listOf overlayType;
            description = ''
              List of overlays to use with the Nix Packages collection. (For
              details, see the Nixpkgs documentation.) It allows you to
              override packages globally. This is a function that takes as
              an argument the *original* Nixpkgs. The
              first argument should be used for finding dependencies, and
              the second should be used for overriding recipes.

              If `null`, then the overlays are taken from
              the fallback location, for example,
              {file}`~/.config/nixpkgs/overlays`.

              Like {var}`nixpkgs.config` this option only
              applies within the Home Manager configuration. See
              {var}`nixpkgs.config` for a suggested setup that
              works both internally and externally.
            '';
          };

          system = lib.mkOption {
            type = lib.types.str;
            example = "i686-linux";
            default = system;
            description = ''
              Specifies the Nix platform type for which the user environment
              should be built. If unset, it defaults to the platform type of
              your host system. Specifying this option is useful when doing
              distributed multi-platform deployment, or when building
              virtual machines.
            '';
          };
        };
        config = lib.mkMerge [
          (lib.mkIf (cfg.config == {} || isNull cfg.config) {
            _module.args.pkgs = lib.mkOverride 101 finalPkgs.__splicedPackages;
          })
          (lib.mkIf (!(isNull cfg.config) && cfg.config != {} && !(isNull cfg.overlays)) {
            _module.args.pkgs = lib.mkOverride 101 _pkgs;
          })
        ];
      })
    ];
  });
  _file = ./devenv-modules.nix;
}

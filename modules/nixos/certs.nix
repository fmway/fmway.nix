{ config, lib, pkgs, ... }: let
  tls-cert = {  alts ? [], cname ? "localhost" }:
    pkgs.runCommand "selfSignedCert" { buildInputs = [ pkgs.openssl ]; } ''
      mkdir -p $out
      openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days 365 -nodes \
        -keyout $out/cert.key -out $out/cert.crt \
        -subj "/CN=${cname}" -addext "subjectAltName=DNS:localhost,${builtins.concatStringsSep "," (["IP:127.0.0.1"] ++ alts)}"
    '';

  inherit (lib)
    mkIf
    mkOption
    mkBefore
    types
    mapAttrsToList
    literalExpression
    flatten
    unique
    elemAt
    splitString
    ;

  certModule = types.submodule ({ config, ... }: let
    cert = tls-cert { inherit (config) cname alts; };
  in {
    imports = [
      (lib.mkRenamedOptionModule [ "alt" ] [ "alts" ])
    ];
    options = {
      cname = mkOption {
        type = types.str;
        default = "localhost";
        description = "cname for the cert";
        example = literalExpression ''"download.mikrotik.com"'';
      }; 
      alts = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "other specific domain for that cert";
        example = literalExpression ''[ "DNS:download.mikrotik.com" ]'';
      };
      key = mkOption {
        description = "Result of cert.key";
        readOnly = true;
        type = types.oneOf [ types.str types.path ];
        default = "${cert}/cert.key";
      };
      cert = mkOption {
        description = "Result of cert.crt";
        readOnly = true;
        type = types.oneOf [ types.str types.path ];
        default = "${cert}/cert.crt";
      };
    };
  });

  cfg = config.services.certs;

in {
  options.certs = mkOption {
    type = types.attrs;
    default = {};
  };
  options.services.certs = mkOption {
    type = types.attrsOf certModule;
    description = ''
      simple options to generate cert, then you can import the cert file (config.services.certs.<name>.(key|cert)). e.g:
      ```nix
      services.certs = {
        forgejo.cname = "forgejo.local";
        forgejo.alt = [ "DNS:forgejo.local" "DNS:www.forgejo.local" ];
      };

      services.caddy.virtualHosts = {
        "https://forgejo.local" = lib.mkIf config.services.forgejo.enable {
          serverAliases = [ "www.forgejo.local" ];
          extraConfig = with config.services; /* caddy */ ${"''"}
            tls ''${certs.forgejo.cert} ''${certs.forgejo.key}
            log {
              format console
              output stdout
            }
            reverse_proxy localhost:''${toString forgejo.settings.server.HTTP_PORT}
          ${"''"};
        };
      };
      ```
    '';
    example = literalExpression /* nix */ ''
    {
      cgi.cname = "cgi.local.com";
      cgi.alts = [ "DNS:cgi.local.com" ];
    }
    '';
    default = {};
  };
  config = mkIf (cfg != { }) {
    # register to pki
    security.pki.certificateFiles = mkBefore (mapAttrsToList (_: v: v.cert) cfg);
    
    networking.hosts."127.0.0.1" = mkBefore (
      unique (
        flatten (
          mapAttrsToList (_: v:
            [v.cname]
            ++ map (x:
              elemAt (splitString ":" x) 1
            ) v.alts
          ) cfg
        )
      )
    );
  };
}

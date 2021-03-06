{ config, lib, ... }: 

let
  sanCertificate = domain: let
    wantedVhosts = lib.filterAttrs (_: attrs: (attrs.useACMEHost or null) == domain) 
      config.services.nginx.virtualHosts;
    serverAliases = lib.flatten (lib.mapAttrsToList (_: vhost: vhost.serverAliases) wantedVhosts);
  in {
    extraDomains = (
      lib.mapAttrs (name: _: null) wantedVhosts
    ) // (lib.foldl (domains: domain: domains // { ${domain} = null; }) {} serverAliases);
    postRun = "systemctl reload nginx.service";
    webroot = "/var/lib/acme/acme-challenge";
  };
in {
  imports = [
    ./blog.nix
    ./devkid.net.nix
    ./dl.nix
    ./glowing-bear.nix
    ./homepage.nix
    ./ip.nix
    ./muc.nix
    #./blog.halfco.de.nix
    #./halfco.de.nix
    ./threema.nix
  ];

  # avoid conflict with sslh by binding to port 4443
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      config.listen = lib.mkDefault [
        { addr = "127.0.0.1"; port = 4443; ssl = true;}
      ];
    });
  };

  config = {
    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # owncloud etc
      clientMaxBodySize = "4G";

      resolver.addresses = ["172.23.75.6"];

      sslDhparam = config.security.dhparams.params.nginx.path;

      virtualHosts."_" = {
        listen = [{ addr = "127.0.0.1"; port = 80; }];
        locations."/stub_status".extraConfig = ''
          stub_status;
          # Security: Only allow access from the IP below.
          allow 127.0.0.1;
          # Deny anyone else
          deny all;
        '';
      };
    };

    security.dhparams = {
      enable = true;
      params.nginx = {};
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    #security.acme.production = false;
    security.acme.certs = {
      "thalheim.io" = sanCertificate "thalheim.io";
      "devkid.net" = sanCertificate "devkid.net";
      #"halfco.de" = sanCertificate "halfco.de";
      "higgsboson.tk" = sanCertificate "higgsboson.tk";
    };

    environment.etc."netdata/python.d/web_log.conf".text = ''
      nginx_log3:
        name: 'nginx'
        path: '/var/spool/nginx/logs/access.log'
    '';

    users.users.netdata.extraGroups = [ "nginx" ];
  };
}

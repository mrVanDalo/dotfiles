{
  services.nextcloud = {
    enable = true;
    hostName = "cloud.thalheim.io";

    nginx.enable = true;
    caching.apcu = true;

    config = {
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbtableprefix = "oc_";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      adminuser = "nextcloudadmin";
      adminpassFile = "/run/keys/nextcloud-admin-password";
      extraTrustedDomains = [
        "cloud.higgsboson.tk"
        "pim.devkid.net"
      ];
    };
  };

  krebs.secret.files.nextcloud-admin-password.owner = "nextcloud";

  users.users.nextcloud.extraGroups = [ "keys" ];
  systemd.services.nextcloud.serviceConfig.SupplementaryGroups = [ "keys" ];

  services.nginx = {
    virtualHosts."cloud.higgsboson.tk" = {
      useACMEHost = "higgsboson.tk";
      forceSSL = true;
      globalRedirect = "cloud.thalheim.io";
    };
    virtualHosts."cloud.thalheim.io" = {
      useACMEHost = "thalheim.io";
      forceSSL = true;
      serverAliases = [ "pim.devkid.net" ];
    };
  };

  services.netdata.httpcheck.checks.nextcloud = {
    url = "https://cloud.thalheim.io/login";
    regex = "Nextcloud";
  };
}

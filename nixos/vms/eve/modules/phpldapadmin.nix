{ pkgs, ... }:
{
  services.phpfpm.pools.phpldapadmin = {
    listen = "/run/phpfpm-phpldapadmin.sock";
    user = "phpldapadmin";
    group = "phpldapadmin";
    settings = {
      "listen.owner" = "nginx";
      "listen.group" = "nginx";
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.start_servers" = 1;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 1;
      "pm.max_requests" = 500;
    };
  };

  services.nginx = {
    virtualHosts."ldap.thalheim.io" = {
      useACMEHost = "thalheim.io";
      forceSSL = true;
      extraConfig = ''
        index index.php;
      '';
      locations."/".extraConfig = ''
        try_files $uri $uri/ /index.php?$args;
      '';
      locations."~* ^.+\.php$".extraConfig = ''
        include ${pkgs.nginx}/conf/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/run/phpfpm-phpldapadmin.sock;
        fastcgi_index index.php;
      '';
      root = "${pkgs.nur.repos.mic92.phpldapadmin}/share/phpldapadmin";
    };
    virtualHosts."ldap.higgsboson.tk" = {
      useACMEHost = "higgsboson.tk";
      forceSSL = true;
      globalRedirect = "ldap.thalheim.io";
    };
  };

	environment.etc."phpldapadmin/config.php".text = ''
    <?php
    $config->custom->appearance['hide_template_warning'] = true;

    $servers = new Datastore();
    $servers->newServer('ldap_pla');

    $servers->setValue('server','name','Eve LDAP Server');
    $servers->setValue('server','host','127.0.0.1');
    $servers->setValue('login','bind_id','cn=admin,dc=eve');
    $servers->setValue('appearance','password_hash','ssha');
    $servers->setValue('login','anon_bind',false);
    ?>
  '';

  users.users.phpldapadmin = {
    isSystemUser = true;
    createHome = true;
    group = "phpldapadmin";
  };

  users.groups.phpldapadmin = {};

  services.netdata.httpcheck.checks.phpldapadmin = {
    url = "https://ldap.thalheim.io";
    regex = "phpLDAPadmin";
  };
}

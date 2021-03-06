{ pkgs, ... }: {

  users.ldap = {
    enable = true;
    server = "ldap://127.0.0.1/";
    base = "ou=users,dc=eve";
    daemon.enable = true;
    bind = {
      distinguishedName = "cn=login,ou=system,ou=users,dc=eve";
      passwordFile = "/run/keys/ldap-login";
    };
  };

  services.openldap = {
    enable = true;
    suffix = "dc=eve";
    rootdn = "cn=admin,dc=eve";
    rootpwFile = "/run/keys/openldap-rootpw";
    extraConfig = ''
      # Mailserver schema used with postfix
      include ${./openldap}/mailserver.schema
      include ${./openldap}/owncloud.schema
      include ${./openldap}/ttrss.schema
      include ${./openldap}/gitlab.schema
      include ${./openldap}/pyload.schema
      include ${./openldap}/nginx.schema
      include ${./openldap}/jabber.schema
      include ${./openldap}/proxy.schema
      include ${./openldap}/seafile.schema
      include ${./openldap}/openssh-lpk-openldap.schema
      include ${./openldap}/grafana.schema

      access to attrs=userPassword
        by self         write
        by anonymous    auth
        by dn="cn=dovecot,dc=mail,dc=eve" read
        by dn="cn=gitlab,ou=system,ou=users,dc=eve" read
        by *            none
      access to attrs=loginShell
        by self write
        by * read
      access to dn.subtree="ou=system,ou=users,dc=eve"
        by dn="cn=dovecot,dc=mail,dc=eve" read
        by dn.subtree="ou=system,ou=users,dc=eve" read
        by * none
      access to dn.subtree="ou=jabber,ou=users,dc=eve"
        by dn="cn=prosody,ou=system,ou=users,dc=eve" write
        by * read
      access to *
        by * read
    '';
  };

  krebs.secret.files.openldap-rootpw.owner = "openldap";
  krebs.secret.files.ldap-login = {};

  users.users.openldap.extraGroups = [ "keys" ];
  systemd.services.openldap.serviceConfig.SupplementaryGroups = [ "keys" ];
  services.netdata.portcheck.checks.openldap.port = 389;
}

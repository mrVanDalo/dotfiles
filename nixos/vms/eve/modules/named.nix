{ config, ... }: {
  services.resolved.enable = false;
  networking.nameservers = [ "127.0.0.1" ];

  services.bind = {
    enable = true;
    forwarders = [ "9.9.9.9" ];
    cacheNetworks = [ "any" ];
    extraConfig = ''
      include "/run/keys/chelnok.key";
      server 89.238.64.7 {
        transfer-format many-answers;
        keys { ns.chelnok.de-ns1.higgsboson.tk.;};
      };
      server 2a00:1828:a013:f00::3 {
        transfer-format many-answers;
        keys { ns.chelnok.de-ns1.higgsboson.tk.;};
      };
      statistics-channels { 
        inet 127.0.0.1 port 8053 allow { 127.0.0.1; }; 
      };
    '';
    extraOptions = ''
      allow-recursion {
        localhost;
        localnets;
        172.23.75/24;
        fd42:4992:6a6d::/64;
        ${config.networking.eve.ipv6.subnet};
        ${config.networking.eve.ipv4.address}/32;
      };
    '';
    zones = let
      chelnok = [
        "89.238.64.7"
        "2a00:1828:a013:f00::3"
      ];
    in [{
      name = "chelnok.de.";
      master = false;
      file = "chelnok.de.zone";
      masters = chelnok;
    } {
      name = "nek0.eu.";
      master = false;
      file = "nek0.eu.zone";
      masters = chelnok;
    } {
      name = "nek0.cat.";
      master = false;
      file = "nek0.cat.zone";
      masters = chelnok;
    } {
      name = "nek0.space.";
      master = false;
      file = "nek0.space.zone";
      masters = chelnok;
    }];
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  users.users.named.extraGroups = [ "keys" ];
  systemd.services.bind.serviceConfig.SupplementaryGroups = [ "keys" ];

  krebs.secret.files."chelnok.key".owner = "named";
}

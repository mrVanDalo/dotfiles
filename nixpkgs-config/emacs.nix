
{ pkgs, lib, config, ... }:

let
  editorScript = pkgs.writeScriptBin "emacseditor" ''
    #!${pkgs.runtimeShell}
    export TERM=xterm-24bit
    exec -a emacs ${pkgs.emacs}/bin/emacsclient \
      --socket-name $XDG_RUNTIME_DIR/emacs \
      --create-frame \
      --alternate-editor ${pkgs.emacs}/bin/emacs \
      -nw "$@"
  '';

in {
  options = {
    programs.emacs.socket-activation.enable = (lib.mkEnableOption "socket-activation") // {
      default = true;
    };
  };
  config = lib.mkMerge [
    ({
      home.packages = with pkgs; [
        editorScript
        gocode
        godef
        gocode
        go-tools
        gogetdoc
        impl
        gometalinter
        nur.repos.mic92.xterm-24bit-terminfo
      ];
    })
    (lib.mkIf config.programs.emacs.socket-activation.enable {
      systemd.user.sockets.emacs-daemon = {
        Socket.ListenStream = "%t/emacs";
        Install.WantedBy = [ "sockets.target" ];
      };

      systemd.user.services.emacs-daemon = {
        Unit = {
          Requires = [ "emacs-daemon.socket" ];
          RefuseManualStart = true;
        };
        Service = {
          Type = "forking";
          ExecStart = "${pkgs.zsh}/bin/zsh -c 'source ~/.zshrc; export PATH=$PATH:${pkgs.sqlite}/bin; exec ${pkgs.emacs}/bin/emacs --daemon'";
          Restart = "always";
        };
      };
    })
  ];
}

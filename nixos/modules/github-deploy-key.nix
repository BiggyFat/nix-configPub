{
  lib,
  pkgs,
  ...
}: let
  # Chemin de la clé dans le système (root only)
  deployKey = "/etc/ssh/deploy_key";
in {
  #####################################################################
  # 1) Installer la clé privée + droits 600
  environment.etc."ssh/deploy_key".source = ../secrets/deploy_key;
  systemd.tmpfiles.rules = [
    "C  ${deployKey}  0600  root  root  - -"
  ];

  #####################################################################
  # 2) SSH : dire à git@github.com d’utiliser cette clé
  programs.ssh.extraConfig = ''
    Host github.com
      User git
      IdentityFile ${deployKey}
  '';

  #####################################################################
  # 3) Git : réécrire automatiquement l’URL https→ssh
  programs.git = {
    enable = true;
    extraConfig = {
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
    };
  };

  # (Optionnel) si tu veux être strict : ajoute l’empreinte hostkey.
  # security.ssh.knownHosts."github.com".publicKey = "...";
}

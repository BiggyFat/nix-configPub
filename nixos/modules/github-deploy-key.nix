{lib, ...}: let
  deployKey = "/etc/ssh/deploy_key";
in {
  # 1. Clé privée pour root
  environment.etc."ssh/deploy_key".source = ../secrets/deploy_key;
  systemd.tmpfiles.rules = ["C ${deployKey} 0600 root root - -"];

  # 2. SSH : forcer l’usage de la clé pour GitHub
  programs.ssh.extraConfig = ''
    Host github.com
      User git
      IdentityFile ${deployKey}
  '';

  # 3. Git : réécrire https → ssh  (nouvelle option)
  programs.git = {
    enable = true;
    config = {
      # section git :   [url "git@github.com:"]
      #                   insteadOf = https://github.com/
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
    };
  };
}

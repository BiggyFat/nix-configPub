{ pkgs, ... }: {
  imports = [
    ./_common.nix
  ];

  home = {
    username = "admin";
    homeDirectory = "/home/admin";
  };

  # Paquets installés UNIQUEMENT pour l'utilisateur 'admin'
  home.packages = with pkgs; [
    # Exemples de paquets que seul l'admin pourrait vouloir :
    htop      # Un moniteur de processus en terminal
    gparted   # Un outil de gestion de partitions
  ];
}

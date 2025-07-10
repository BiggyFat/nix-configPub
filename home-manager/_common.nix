# This is a SHARED home-manager configuration file
{pkgs, ...}: {
  # Activer les paquets non-libres si besoin
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  # Activer home-manager et git (bonnes pratiques)
  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Ajoutez ici les paquets que vous voulez pour vos utilisateurs
  # J'ai gardé ceux que vous aviez mis.
  home.packages = with pkgs; [
    # neovim
    # steam
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # LA LIGNE LA PLUS IMPORTANTE : La version doit correspondre à nixpkgs
  home.stateVersion = "24.05";
}

{ config, pkgs, ... }:

{
  # Copier l'image dans /etc/wallpapers lors du rebuild
  environment.etc."wallpapers/default-wallpaper.jpg".source = ./assets/wallpapers/default-wallpaper.jpg;

  # Configurer Hyprland pour utiliser l'image comme fond d'écran
  programs.hyprland = {
    enable = true;
    wallpaper = {
      enable = true;
      path = "/etc/wallpapers/default-wallpaper.jpg"; # Chemin cible
    };
  };



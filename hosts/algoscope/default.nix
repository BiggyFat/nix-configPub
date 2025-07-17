# /hosts/algoscope/default.nix
#
# C'est la configuration spécifique à l'hôte 'algoscope'.
# Son seul rôle est d'assembler les modules dont cette machine a besoin.
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # --- Imports ---
  #
  # 1. Importe la configuration matérielle de cette machine.
  imports = [
    ./hardware-configuration.nix

    # 2. Importe la configuration commune à toutes les machines.
    ../common.nix

    # 3. Importe nos modules de fonctionnalités (GNOME et services).
    ../../modules/nixos/gnome.nix
    ../../modules/nixos/services.nix
  ];

  # --- Paramètres spécifiques à l'hôte ---

  # Définit le nom d'hôte pour cette machine.
  networking.hostName = "algoscope";

  # On définit ici le nom de l'interface Wi-Fi pour CETTE machine spécifique.
  networking.wifi.interfaceName = "wlo1";
  
  # Algoscope specific packages
  environment.systemPackages = with pkgs; [
    librealsense
  ];
  
  # On s'assure que le driver générique des webcams est chargé au démarrage.
  # C'est essentiel pour la stabilité d'applications comme guvcview.
  boot.kernelModules = [ "uvcvideo" ];

  # Ceci est requis par NixOS. Ne le changez pas.
  system.stateVersion = "25.05";
}

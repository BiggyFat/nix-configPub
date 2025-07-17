# /hosts/common.nix
#
# Ce fichier contient les paramètres système partagés par tous les hôtes.
# Il définit nos utilisateurs, les paquets communs, et les paramètres de base du système.
{
  lib,
  config,
  pkgs,
  inputs,
  adminUser,
  serviceUser,
  ...
}:

{
  # On peut laisser les imports à ce niveau.
  imports = [
    ../overlays
  ];

  # --- DÉFINITION D'OPTIONS PERSONNALISÉES ---
  #
  # On déclare ici les nouvelles options que l'on pourra utiliser dans nos modules.
  # Cela permet de centraliser la "forme" de nos options personnalisées.
  options.networking.wifi.interfaceName = lib.mkOption {
    type = lib.types.str; # Le type de l'option est une chaîne de caractères (string).
    default = null; # On force chaque hôte à définir cette valeur.
    description = "The name of the primary WiFi interface (e.g., wlo1).";
  };

  # --- ASSIGNATION DES VALEURS DE CONFIGURATION ---
  #
  # Toutes les valeurs de configuration du système (tout ce qui modifie
  # réellement le système) doivent être dans ce bloc 'config'.
  config = {
    # --- Users ---
    users.users = {
      # Définit l'utilisateur administrateur. C'est votre compte principal interactif.
      ${adminUser} = {
        isNormalUser = true; # Un utilisateur normal qui peut se connecter.
        description = "Admin User";
        initialPassword = "admin";
        extraGroups = [
          "wheel"
          "video"
        ]; # Le groupe 'wheel' donne les privilèges sudo.
      };

      # Définit l'utilisateur de service.
      ${serviceUser} = {
        isNormalUser = true; # Un utilisateur normal qui peut se connecter.
        description = "Service User";
        hashedPassword = "";
        extraGroups = [ "video" ];
      };

      # Définit l'utilisateur système dédié à l'exécution de nos services.
      "app-runner" = {
        isSystemUser = true; # Un utilisateur système, ne peut pas se connecter par défaut.
        group = "app-runners";
        extraGroups = [ "video" ];
      };
    };
    # Crée un groupe dédié pour l'utilisateur de service.
    users.groups."app-runners" = { };

    # --- Bootloader ---
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # --- Networking ---
    networking.networkmanager.enable = true;
    # On active le pare-feu de NixOS de manière déclarative.
    networking.firewall.enable = true;

    # --- Localization ---
    time.timeZone = "Europe/Paris";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };

    # --- System Packages ---
    environment.systemPackages = with pkgs; [
      wget
      git
      vim
      tree # Utilitaire pour afficher l'arborescence des fichiers
      ffmpeg # Outil puissant pour la manipulation multimédia
    ];

    # --- Nix Settings ---
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;

    # --- Security ---
    # Active sudo pour les utilisateurs dans le groupe 'wheel'.
    security.sudo.enable = true;
  };
}

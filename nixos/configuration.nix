# nixos/configuration.nix
{
  inputs,
  lib,
  config,
  pkgs,
  serviceUser,
  ...
}:
let
  pythonEnvironments = import ./modules/python-envs.nix { inherit pkgs; };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot loader setup and config
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };

  # Allow unfree pkgs
  nixpkgs.config.allowUnfree = true;

  #Port configuration 3000
  networking.firewall.allowedTCPPorts = [ 3000 ];

  boot.kernelModules = [ "uvcvideo" ];

  hardware.graphics.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  # Activate global AppImage support
  programs.appimage = {
    enable = true; # monte les images squashFS, etc.
    binfmt = true; # enregistre une règle binfmt → exécution transparente
  };

  # VM Tools
  # virtualisation.vmware.guest.enable = true;
  # Time zone
  time.timeZone = "Europe/Paris";
  # Hostname
  networking.hostName = "algoscope0024";

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    xkb = {
      layout = "fr";
      variant = "azerty";
    };
    desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.shell]
      favorite-apps=['MonApp.desktop','org.gnome.Nautilus.desktop']
    '';
    desktopManager.gnome.extraGSettingsOverridePackages = [
      pkgs.gsettings-desktop-schemas # nécessaire pour les schémas GNOME
      pkgs.gnome-shell # pour les clés de org.gnome.shell
    ];
  };
  i18n.defaultLocale = "fr_FR.UTF-8";

  services.udev.enable = true;
  services.udev.packages = [ pkgs.librealsense ];

  hardware.enableRedistributableFirmware = true;

  # Definition of the different users
  users.users = {
    admin = {
      initialPassword = "admin";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
      ];
      # Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [
        "wheel"
        "video"
      ];
    };
    ${serviceUser} = {
      hashedPassword = "";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
      ];
      # Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [ "video" ];
    };
  };

  # Dedicated system user
  users.users.app-runner = {
    isSystemUser = true;
    group = "app-runners";
    extraGroups = [ "video" ];
  };
  users.groups.app-runners = { };

  # Service definition
  systemd.services.server_camera = {
    description = "Python Camera Service";
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [ v4l-utils ];

    serviceConfig = {
      User = "app-runner";
      Group = "app-runners";

      WorkingDirectory = "${pkgs.serverCam}/share/server_cam";
      ExecStart = "${pythonEnvironments.cameraServerEnv}/bin/python ${pkgs.serverCam}/share/server_cam/server_camera.py";

      StateDirectory = "server_camera";
      StandardOutput = "journal";
      StandardError = "journal";
      Restart = "on-failure";
      RestartSec = "10s";
      DynamicUser = true;
    };
  };

  # Wi-Fi Service
  systemd.services.wifi-power-save-off = {
    unitConfig = {
      Description = "Disable Wi-Fi power management";
      ConditionPathExists = "/sys/class/net/wlo1";
    };

    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.iw ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.iw}/bin/iw dev wlo1 set power_save off";
    };
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = false;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    tree
    brave-unstable
    rustdesk-flutter # RustDesk for remote
    librealsense-gui
    librealsense
    guvcview
    ffmpeg # For ffplay
    nftables # To replace existing {ip, ip6, arp, eb} tables framework
    nixfmt-rfc-style # Nix official formatter
    nixfmt-tree
    gnomeExtensions.desktop-icons-ng-ding
    appimage-run # To make AppImage file executable
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}

# /modules/nixos/services.nix
#
# Ce module définit tous les services systemd personnalisés.
{
  lib,
  config,
  pkgs,
  ...
}:

# On utilise un bloc 'let' pour préparer nos commandes complexes.
let
  # On prépare la commande pour le service Python ici.
  pythonCameraCommand =
    let
      pythonEnv = pkgs.python3.withPackages (ps: [
        ps.spyder-kernels
        ps.numpy
        ps.requests
        ps.dill
        ps.pycurl
        pkgs.open3d
        ps.pyrealsense2
        ps.pillow
        ps.pyttsx3
        ps.pylibdmtx
        ps.zxing-cpp
        ps.opencv4
        ps.pyudev
        ps.natsort
        ps.fastapi
        ps.uvicorn
        ps.gunicorn
        ps.pyscard
      ]);
      cameraPackage = pkgs.server-camera;
    in
    "${pythonEnv}/bin/python ${cameraPackage}/share/server-cam/server_camera.py";

in
{
  systemd.services = {
    # --- Service de caméra Python ---
    # J'ai aussi changé le nom du service pour être conforme aux standards (pas de majuscule)
    server-camera = {
      description = "A custom Python service for the camera server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      # On ajoute le paquet v4l-utils au PATH du service.
      # Cela rend la commande 'v4l2-ctl' disponible pour notre script.
      path = [ pkgs.v4l-utils ];

      serviceConfig = {
        User = "app-runner";
        Group = "app-runners";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      script = pythonCameraCommand;
    };

    # --- Service de veille WiFi ---
    disable-wifi-standby = {
      description = "Disable WiFi power saving";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      # On se lie à l'interface définie dans la configuration de l'hôte.
      # La variable ${config.networking.wifi.interfaceName} sera remplacée par
      # le nom correct sur cette machine.
      bindsTo = [ "sys-subsystem-net-devices-${config.networking.wifi.interfaceName}.device" ];

      serviceConfig = {
        User = "app-runner";
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "10s";
        # On donne au service la seule capacité dont il a besoin pour
        # modifier les paramètres réseau.
        AmbientCapabilities = "CAP_NET_ADMIN";
      };

      script = "${pkgs.iw}/bin/iw dev ${config.networking.wifi.interfaceName} set power_save off";
    };
  };

  # --- GESTION DES PORTS POUR LES SERVICES ---
  #
  # On utilise lib.mkIf pour n'ouvrir le port QUE si le service est activé.
  networking.firewall.allowedTCPPorts = lib.mkIf config.systemd.services.server-camera.enable [
    3000
  ];
}

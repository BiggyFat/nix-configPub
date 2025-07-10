# nixos/modules/server-camera.nix
{
  pkgs,
  self,
  ...
}: let
  serverCam = pkgs.stdenv.mkDerivation {
    pname = "server-camera";
    version = "1.0";
    src = ./../../VP/server_cameras;
    installPhase = ''
      mkdir -p $out/share/server_cam
      cp server_camera.py no_picture.jpg $out/share/server_cam/
    '';
  };
in {
  nixpkgs.overlays = [
    (final: prev: {serverCam = serverCam;})
  ];
}

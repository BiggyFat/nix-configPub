# /pkgs/server-camera/default.nix
#
# Ce paquet combine le script Python et ses ressources (images).
{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "server-camera";
  version = "1.0";

  # La source est le dossier qui contient nos fichiers.
  src = ../../scripts;

  # On ne dépaquette rien, on utilise directement les sources.
  dontUnpack = true;

  # On copie le script et l'image dans le dossier de sortie.
  installPhase = ''
    mkdir -p $out/share/server-cam
    cp ${src}/server_camera.py $out/share/server-cam/
    cp ${src}/no_picture.jpg $out/share/server-cam/
  '';
}

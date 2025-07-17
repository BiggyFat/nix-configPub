# /pkgs/algolink/default.nix
#
# This file packages the AlgoLink.AppImage so it can be installed
# and managed like any other Nix package.
{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "algolink";
  version = "1.0"; # You can change this version

  # The source of our package is the AppImage file in this same directory.
  src = ./algolink.AppImage;

  # We need a tool called 'appimage-run' to properly execute the AppImage.
  nativeBuildInputs = [
    pkgs.appimage-run
    pkgs.makeWrapper
  ];

  # Au lieu d'essayer de décompresser, on copie simplement le fichier source
  # dans le répertoire de construction.
  unpackPhase = ''
    cp $src algolink.AppImage
  '';

  # The installation phase:
  # 1. Create the bin directory.
  # 2. Create a wrapper script that runs the AppImage using appimage-run.
  # 3. Make the AppImage itself and the wrapper script executable.
  installPhase = ''
    mkdir -p $out/bin

    # Copy the AppImage into the Nix store.
    cp algolink.AppImage $out/algolink.AppImage
    chmod +x $out/algolink.AppImage

    # Create the wrapper script.
    makeWrapper "${pkgs.appimage-run}/bin/appimage-run" $out/bin/algolink \
      --add-flags "$out/algolink.AppImage"
  '';

  meta = with pkgs.lib; {
    description = "AlgoLink Application";
    license = licenses.unfree; # AppImages are typically unfree
    platforms = platforms.linux;
  };
}

# /modules/home-manager/common.nix
#
# Shared Home Manager settings for all interactive users.
{ pkgs, ... }:
{
  # Set the home-manager state version.
  home.stateVersion = "25.05";

  # Install common packages for all users.
  home.packages = with pkgs; [
    git
    htop
    brave
    rustdesk-flutter # Client de bureau à distance
    # Extension GNOME
    gnomeExtensions.desktop-icons-ng-ding
    algolink # RustDesk algolink.AppImage
    guvcview
    librealsense-gui
  ];
}

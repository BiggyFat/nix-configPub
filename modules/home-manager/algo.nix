# /modules/home-manager/algo.nix
#
# Home Manager settings specifically for the '${serviceUSer}' user.
{ config, pkgs, ... }:
{
  # Import the common settings that all users share.
  imports = [ ./common.nix ];

  # Install packages only for this user.
  # This includes our custom 'algolink' package.
  home.packages = with pkgs; [
  ];

  # --- GNOME Dock Pinning ---
  # This is how we pin the application to the dock.
  dconf.settings = {
    "org/gnome/shell" = {
      # List the .desktop file names of your favorite apps.
      # We add our algolink.desktop to the list of default favorites.
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "brave.desktop"
        "org.gnome.Terminal.desktop"
        "algolink.desktop" # This must match the desktop file in the AppImage
      ];
    };
  };
}

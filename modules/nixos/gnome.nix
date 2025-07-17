# /modules/nixos/gnome.nix
#
# This module contains all the system-level settings for the GNOME desktop environment.
# Keeping this separate allows you to easily switch desktop environments on a host
# or even create a server host without a graphical interface.
{ config, pkgs, ... }:

{
  # --- X Server and Desktop Environment ---
  # Enable the X server, which is the foundation for graphical environments.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Manager (GDM) for the login screen.
  services.displayManager.gdm.enable = true;

  # Enable the GNOME desktop environment itself.
  services.desktopManager.gnome.enable = true;

  # --- Sound ---
  # Enable sound support with PipeWire, the modern standard.
  security.rtkit.enable = true; # Real-time scheduling for audio.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # (Optional) If you use JACK applications, you can enable this.
    # jack.enable = true;
  };

  # --- dconf ---
  # Enable dconf to allow Home Manager to manage GNOME settings.
  # This is crucial for pinning applications to the dock.
  programs.dconf.enable = true;
}

{ pkgs, ... }:

{
  # 1. paquet algolink déjà dans systemPackages
  environment.systemPackages = [ pkgs.algolink ];

  # 2. réglage GSettings pour tous les comptes GNOME
  services.xserver.desktopManager.gnome = {
    # paquets contenant les schémas à surcharger
    extraGSettingsOverridePackages = with pkgs; [
      gsettings-desktop-schemas
      gnome-shell # fournit org.gnome.shell
    ];

    extraGSettingsOverrides = ''
      [org.gnome.shell]
      favorite-apps=['algolink.desktop','org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop']
    '';
  };
}

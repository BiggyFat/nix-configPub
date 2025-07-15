# home-manager/admin.nix
{ pkgs, ... }:
{
  imports = [
    ./_common.nix
  ];

  home = {
    username = "admin";
    homeDirectory = "/home/admin";
  };

  # Admin package only
  home.packages = with pkgs; [
    htop # Process monitor in terminal
    gparted
  ];
}

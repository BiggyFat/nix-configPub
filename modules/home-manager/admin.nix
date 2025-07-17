# /modules/home-manager/admin.nix
#
# Home Manager settings specifically for the 'admin' user.
{ pkgs, ... }:
{
  # Import the common settings that all users share.
  imports = [ ./common.nix ];

  # Install packages only for the admin user.
  home.packages = with pkgs; [
    nix-tree # A useful tool for debugging Nix derivations
    gparted
    guvcview # Camera visualisation application
  ];

  # Basic configuration for git.
  programs.git = {
    enable = true;
    userName = "BaronVonMuller";
    userEmail = "raphael.muller02@gmail.com";
  };
}

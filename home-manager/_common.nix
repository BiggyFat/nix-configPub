# home-manager/_common.nix
{ pkgs, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Global user package
  home.packages = with pkgs; [
  ];

  # Reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}

# home-manager/algo.nix
{
  serviceUser,
  pkgs,
  ...
}:
{
  imports = [
    ./_common.nix
  ];

  home = {
    username = serviceUser;
    homeDirectory = "/home/${serviceUser}";
  };

  # Algo package only
  home.packages = with pkgs; [
  ];
}

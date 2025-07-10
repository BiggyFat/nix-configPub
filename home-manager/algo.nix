{serviceUser, pkgs,  ...}: {
  imports = [
    ./_common.nix
  ];

  home = {
    username = serviceUser;
    homeDirectory = "/home/${serviceUser}";
  };
  
  # Paquets installés UNIQUEMENT pour l'utilisateur 'serviceUser'
  home.packages = with pkgs; [

  ];
}

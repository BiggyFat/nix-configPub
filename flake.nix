# flake.nix
#
# Entrée principale pour gérer la configuration NixOS et Home Manager.
# Ce fichier définit les dépendances (inputs) et les configurations (outputs).
# Il inclut également une intégration Hyprland avec un fond d'écran personnalisé.

{
  description = "A modular and scalable NixOS configuration by BiggyFat";

  # -----------------------------------------------------------------------------
  # --- INPUTS ------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  #
  # Dépendances externes (inputs) utilisées pour construire la configuration.
  inputs = {
    # Le dépôt officiel de NixOS. Utilise la branche unstable.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager : gestion des configurations utilisateur.
    home-manager = {
      url = "github:nix-community/home-manager";
      # Synchronise nixpkgs entre Home Manager et le système.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS Hardware : configurations matérielles spécifiques.
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  # -----------------------------------------------------------------------------
  # --- OUTPUTS -----------------------------------------------------------------
  # -----------------------------------------------------------------------------
  #
  # Sorties (outputs) définissant les configurations NixOS et Home Manager.
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      # --- Variables Globales ---
      # Définies une seule fois ici pour être utilisées dans les modules.
      system = "x86_64-linux"; # Architecture de la machine.
      adminUser = "admin";     # Utilisateur principal.
      serviceUser = "algo";    # Utilisateur pour les services.
      pkgs = nixpkgs.legacyPackages.${system}; # Packages Nix disponibles.
    in
    {
      # --- Configurations NixOS ---
      #
      # Définition des configurations pour chaque machine (hôte).
      nixosConfigurations = {
        # Configuration principale pour la machine "algoscope".
        "algoscope" = nixpkgs.lib.nixosSystem {
          inherit system;

          # Variables partagées avec les modules (inputs et utilisateurs).
          specialArgs = { inherit inputs adminUser serviceUser; };

          # Modules utilisés pour assembler la configuration finale.
          modules = [
            # 1. Configuration spécifique à l'hôte.
            ./hosts/algoscope

            # 2. Activation du module Home Manager.
            home-manager.nixosModules.home-manager

            # 3. Configuration utilisateur avec Home Manager.
            {
              home-manager = {
                useGlobalPkgs = true;   # Utilise nixpkgs au niveau système.
                useUserPackages = true; # Permet à Home Manager d'installer des paquets.

                # Variables partagées avec les modules Home Manager.
                extraSpecialArgs = { inherit inputs adminUser serviceUser; };

                # Gestion des utilisateurs via Home Manager.
                users.${adminUser} = import ./modules/home-manager/admin.nix;
                users.${serviceUser} = import ./modules/home-manager/algo.nix;
              };
            }

            # 4. Module pour Hyprland et le fond d'écran.
            ./modules/wallpaper.nix
          ];
        };
      };

      # --- Environnement de Développement ---
      #
      # Fournit un shell de développement avec les outils nécessaires.
      devShells.${system}.default = pkgs.mkShell {
        # Paquets disponibles dans le shell de développement.
        packages = with pkgs; [
          nixfmt       # Formatteur pour les fichiers Nix.
          nix-tree     # Visualisation des dépendances des dérivations Nix.
          vim          # Éditeur de texte ou tout autre outil que tu préfères.
        ];
      };
    };
}

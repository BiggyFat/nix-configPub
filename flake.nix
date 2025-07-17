# /flake.nix
#
# This is the main entry point for the NixOS configuration.
# It defines the dependencies (inputs) and what to build (outputs).
# The logic is kept minimal here, mostly pointing to other files
# in the repository to promote modularity and readability.
{
  description = "A modular and scalable NixOS configuration by BaronVonMuller";

  # -----------------------------------------------------------------------------
  # --- INPUTS ------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  #
  # All external dependencies (e.g., nixpkgs, home-manager) are defined here.
  # This makes it easy to update them from a central location.
  inputs = {
    # The official NixOS package repository. We follow the unstable channel.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager, for managing user-specific configurations declaratively.
    home-manager = {
      url = "github:nix-community/home-manager";
      # Ensure home-manager uses the same nixpkgs revision as the system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # (Optional but good practice) Hardware-specific configurations from the community.
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  # -----------------------------------------------------------------------------
  # --- OUTPUTS -----------------------------------------------------------------
  # -----------------------------------------------------------------------------
  #
  # This function defines what the flake builds.
  # We define our NixOS systems (hosts) and home-manager configurations here.
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      # --- Global Variables ---
      # Define variables that are shared across all hosts and modules.

      # The system architecture.
      system = "x86_64-linux";

      # The username for the main interactive user (with sudo).
      adminUser = "admin";

      # The username for the service user
      serviceUser = "algo";

      pkgs = nixpkgs.legacyPackages.${system};

    in
    {
      # --- NixOS Configurations ---
      #
      # This is where we define each of our machines (hosts).
      # Each host is an entry in this set.
      nixosConfigurations = {
        # Define your primary machine.
        # The configuration is built by nixosSystem, a function from nixpkgs.
        "algoscope" = nixpkgs.lib.nixosSystem {
          inherit system;

          # specialArgs are passed to all modules. This is how we pass down
          # our inputs and global variables like 'serviceUser'.
          specialArgs = { inherit inputs adminUser serviceUser; };

          # The list of modules that make up this host's configuration.
          # This is where we assemble the final system from our modular components.
          modules = [
            # 1. The host-specific configuration (hostname, hardware, etc.)
            #    Nix will automatically look for a `default.nix` in this directory.
            ./hosts/algoscope

            # 2. The Home Manager module itself. This is required to enable it.
            home-manager.nixosModules.home-manager

            # 3. The configuration for Home Manager.
            {
              home-manager = {
                useGlobalPkgs = true; # Use system-level nixpkgs.
                useUserPackages = true; # Allow home-manager to install packages.

                # Pass flake inputs and specialArgs down to home-manager modules.
                extraSpecialArgs = { inherit inputs adminUser serviceUser; };

                # Define which user will be managed by Home Manager.
                # We use the 'serviceUser' variable to make it dynamic.
                # The actual user configuration is imported from our modules directory.
                users.${adminUser} = import ./modules/home-manager/admin.nix;
                users.${serviceUser} = import ./modules/home-manager/algo.nix;
              };
            }
          ];
        };

        # You can easily add another host here in the future:
        # "laptop" = nixpkgs.lib.nixosSystem { ... };
      };

      # --- Environnement de Développement ---
      #
      # Ce shell fournit les outils nécessaires pour travailler SUR cette configuration.
      # Il n'est pas inclus dans le système final construit.
      devShells.${system}.default = pkgs.mkShell {
        # Les paquets disponibles lorsque vous lancez 'nix develop'.
        packages = with pkgs; [
          nixfmt-tree # Le formateur de code Nix officiel.
          nix-tree # Outil pour visualiser les dépendances d'une dérivation.
          vim # Ou l'éditeur de votre choix.
        ];
      };

    };
}

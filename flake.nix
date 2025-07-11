# /flake.nix
{
  description = "Your new nix config";

  inputs = {
    nixpkgs          .url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable .url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager     .url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    alejandra        .url = "github:kamadorueda/alejandra";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    alejandra,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-linux"];

    myOverlays = [
      (import ./overlays/open3d.nix)
      (final: prev: {
        brave-unstable = nixpkgs-unstable.legacyPackages.${prev.system}.brave;
      })
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    serviceUser = "algo0024";
  in
    {
      formatter =
        forAllSystems (system:
          alejandra.packages.${system}.default);
    }
    // forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = myOverlays;
        };
      in {
        legacyPackages = pkgs;

        packages.default = pkgs.hello;
        devShells.default = pkgs.mkShell {
          name = "camera-env-test";
          packages = [
            pkgs.alejandra
            (import ./nixos/modules/python-envs.nix {inherit pkgs;}).cameraServerEnv
          ];
        };

        homeConfigurations = {
          "admin@algoscope0024" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [./home-manager/admin.nix];
          };

          "${serviceUser}@algoscope0024" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {inherit serviceUser;};
            modules = [./home-manager/algo.nix];
          };
        };
      }
    )
    // {
      nixosConfigurations.algoscope0024 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # ← ici tu gardes ta machine cible
        modules = [
          ({pkgs, ...}: {nixpkgs.overlays = myOverlays;})
          ./nixos/configuration.nix
          ./nixos/modules/server-camera-package.nix
        ];
        specialArgs = {inherit inputs self serviceUser;};
      };
    };
}

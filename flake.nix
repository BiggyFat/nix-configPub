# /flake.nix
{
  description = "Your new nix config";

  inputs = {
    nixpkgs          .url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable .url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager     .url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    myOverlays = [
      (import ./overlays/open3d.nix) # <- Open3D
      (final: prev: {
        # <- Brave unstable (exemple)
        brave-unstable =
          nixpkgs-unstable.legacyPackages.${prev.system}.brave;
      })
    ];

    pkgs = import nixpkgs {
      inherit system;
      overlays = myOverlays;
    };
    serviceUser = "algo0010";
  in {
    legacyPackages.${system} = pkgs;
    packages.${system}.default = pkgs.hello;

    nixosConfigurations.test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({
          config,
          pkgs,
          ...
        }: {
          nixpkgs.overlays = [
            (import ./overlays/open3d.nix)
            (final: prev: {
              brave-unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.brave;
            })
          ];
        })
        ./nixos/configuration.nix
        ./nixos/modules/server-camera-package.nix
      ];
      specialArgs = {
        inherit inputs self serviceUser;
      };
    };

    homeConfigurations = {
      "admin@test" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home-manager/admin.nix];
      };
      "${serviceUser}@test" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit serviceUser;};
        modules = [./home-manager/algo.nix];
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      name = "camera-env-test";
      packages = [
        pkgs.alejandra
        (import ./nixos/modules/python-envs.nix {inherit pkgs;}).cameraServerEnv
      ];
    };
  };
}

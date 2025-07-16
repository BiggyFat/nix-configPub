{
  description = "Your new nix config";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      ## ────────────── Overlays ──────────────
      myOverlays = [
        (import ./overlays/open3d.nix)
        (final: prev: {
          brave-unstable = nixpkgs-unstable.legacyPackages.${prev.system}.brave;
          algolink = prev.callPackage ./pkgs/algolink.nix { };
        })
      ];

      ## ────────────── Service User definition ──────────────
      serviceUser = "algo0024";

      ## ────────────── Fabrique par architecture ──────────────
      perSystem =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = myOverlays;
            config.allowUnfree = true; # ← algolink est ‹unfree›
          };
        in
        {
          legacyPackages = pkgs;

          packages = {
            algolink = pkgs.algolink;
            default = pkgs.hello;
          };

          apps = {
            algolink = {
              type = "app";
              program = "${pkgs.algolink}/bin/algolink";
              meta = {
                description = "AlgoLink remote‑desktop client (AppImage)";
                mainProgram = "algolink";
              };
            };
          };

          devShells.default = pkgs.mkShell {
            name = "camera-env-test";
            packages = [
              (import ./nixos/modules/python-envs.nix { inherit pkgs; }).cameraServerEnv
            ];
          };
        };

      ## Accès facile au pkgs x86_64 pour Home‑Manager
      pkgsX86 = (perSystem "x86_64-linux").legacyPackages;

    in
    {
      ### ─────────── sorties génériques (formatter, pkgs…) ───────────
      formatter = nixpkgs.lib.genAttrs systems (s: nixpkgs.legacyPackages.${s}.nixfmt-tree);
      packages = nixpkgs.lib.genAttrs systems (s: (perSystem s).packages);
      apps = nixpkgs.lib.genAttrs systems (s: (perSystem s).apps);
      devShells = nixpkgs.lib.genAttrs systems (s: (perSystem s).devShells);
      legacyPackages = nixpkgs.lib.genAttrs systems (s: (perSystem s).legacyPackages);

      ### ─────────── Home‑Manager ───────────
      homeConfigurations = {
        "admin@algoscope0024" = home-manager.lib.homeManagerConfiguration {
          inherit pkgsX86;
          modules = [ ./home-manager/admin.nix ];
        };

        "${serviceUser}@algoscope0024" = home-manager.lib.homeManagerConfiguration {
          inherit pkgsX86;
          extraSpecialArgs = { inherit serviceUser; };
          modules = [ ./home-manager/algo.nix ];
        };
      };

      ### ─────────── NixOS machines ───────────
      nixosConfigurations = {
        algoscope0024 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            (
              { ... }:
              {
                nixpkgs.overlays = myOverlays;
              }
            )
            ./nixos/configuration.nix
            ./nixos/modules/server-camera-package.nix
            ./nixos/modules/algolink-system.nix
          ];

          specialArgs = {
            inherit
              inputs
              self
              serviceUser
              myOverlays
              ;
          };
        };
      };
    };
}

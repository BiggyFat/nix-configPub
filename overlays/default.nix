# /overlays/default.nix
#
# This file acts as the single entry point for all our custom overlays.
# It imports them and applies them to the nixpkgs package set.
{ inputs, ... }:
{
  # This option adds our overlays to the main nixpkgs configuration.
  nixpkgs.overlays = [
    # Import our custom 'open3d' package definition.
    (import ./open3d.nix)

    (self: super: {
      algolink = super.callPackage ../pkgs/algolink { };
    })

    (self: super: {
      server-camera = super.callPackage ../pkgs/server-camera { };
    })

    # If you had another overlay, e.g., 'my-other-app.nix',
    # you would just add it here:
    # (import ./my-other-app.nix)
  ];
}

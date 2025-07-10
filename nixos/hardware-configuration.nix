# Fichier hardware-configuration.nix corrigé et complété
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # Ou "kvm-intel" selon votre CPU
  boot.extraModulePackages = [ ];

  # --- DÉBUT DE LA CORRECTION ---
  fileSystems = {
    # On déclare la partition racine ("/")
    "/" = {
      device = "/dev/nvme0n1p2";
      fsType = "ext4"; # Ou le type de fs que vous avez choisi
    };

    # On déclare la partition de boot
    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat"; # <- On utilise fsType, pas format
    };
  };
  # --- FIN DE LA CORRECTION ---

  swapDevices = [
    { device = "/dev/nvme0n1p3"; }
  ];
  
  nixpkgs.hostPlatform = "x86_64-linux";

  # Activer la mise en veille (hibernate) si vous le souhaitez
  #powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  #hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # Ou pour Intel :
  hardware.cpu.intel.updateMicrocode = true;
}

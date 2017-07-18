# To build, use:
# nix-build nixos -I nixos-config=nixos/modules/installer/cd-dvd/sd-image-aarch64.nix -A config.system.build.sdImage
{ config, lib, pkgs, ... }:

let
  extlinux-conf-builder =
    import ../../system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix {
      inherit pkgs;
    };
in
{
  imports = [
    ../../profiles/installation-device.nix
    ../../profiles/minimal.nix
    ./sd-image.nix
  ];

  assertions = lib.singleton {
    assertion = pkgs.stdenv.system == "aarch64-linux";
    message = "sd-image-aarch64.nix can be only built natively on Aarch64 / ARM64; " +
      "it cannot be cross compiled";
  };

  # Needed by RPi firmware
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs:
    { linux_4_11 = pkgs.linux_4_11.override {
        src = pkgs.fetchFromGitHub {
          owner = "rafaello7";
          repo = "linux-nanopi-m3";
          rev = "2ac1c187e298ae149a0a33ed10cf6a3882d08a6c";
          sha256 = "1h5yvawzla0vqhkk98gxcwc824bhc936bh6j77qkyspvqcw761fr";
        extraConfig =
          ''
            KGDB y
          '';
};
      };
    };
    
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = ["console=ttyS0,115200n8" "console=tty0"];
  boot.consoleLogLevel = 7;
  networking.wireless.enable = false;

  # FIXME: this probably should be in installation-device.nix
  users.extraUsers.root.initialHashedPassword = "";

  sdImage = {
    populateBootCommands = let
      # Contains a couple of fixes for booting a Linux kernel, will hopefully appear upstream soon.
      configTxt = pkgs.writeText "boot.cmd" ''
        fatload mmc 0 0x46000000 zImage
        fatload mmc 0 0x49000000 sun50i-h5-nanopi-neo2.dtb
        setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk0p2 rootwait panic=10 $extra
        bootz 0x46000000 - 0x49000000
      '';
      in ''
        dd if=/dev/zero of=$out bs=1024 seek=544 count=128
        ${pkgs.ubootTools}/bin/mkimage -C none -A arm -T script -d ${configTxt} boot/boot.scr
        ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot
      '';
  };
}


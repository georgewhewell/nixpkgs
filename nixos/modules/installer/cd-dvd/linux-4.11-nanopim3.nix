{ stdenv, hostPlatform, pkgs, perl, buildLinux, ... } @ args:

import ../../../../pkgs/os-specific/linux/kernel/generic.nix (args // rec {
  version = "4.11.6-nanopim3";
  modDirVersion = "4.11.6";
  extraMeta.branch = "4.11";

  src = pkgs.fetchFromGitHub {
    owner = "rafaello7";
    repo = "linux-nanopi-m3";
    rev = "2ac1c187e298ae149a0a33ed10cf6a3882d08a6c";
    sha256 = "1gw8j1dsr9ibnnrpl3acbbfh97pa0iq5f4lwpvxdq6xpfasbjrk5";
  };

  kernelPatches = [
    {
      name = "revert-cross-compile.patch";
      patch = ./revert-cross-compile.patch;
    }
    {
      name = "export-func";
      patch = ./export-func.patch;
    }
  ] ++ pkgs.linux_4_11.kernelPatches;

  features.iwlwifi = true;
  features.efiBootStub = true;
  features.needsCifsUtils = true;
  features.netfilterRPFilter = true;
} // (args.argsOverride or {}))

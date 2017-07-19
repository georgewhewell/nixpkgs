{ stdenv, hostPlatform, pkgs, perl, buildLinux, ... } @ args:

import ../../../../pkgs/os-specific/linux/kernel/generic.nix (args // rec {
  version = "4.11.6-nanopim3";
  modDirVersion = "4.11.6";
  extraMeta.branch = "4.11";

  src = pkgs.fetchFromGitHub {
    owner = "rafaello7";
    repo = "linux-nanopi-m3";
    rev = "723affbd6e5ac4d766649630149a665e59729d4b";
    sha256 = "17i9r0xyp84bm4jmia8pppigxhy5yc1nvn104ifd5h96vhbbjwbl";
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

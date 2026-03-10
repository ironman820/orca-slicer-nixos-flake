{
  description = "Orca Slicer package flake (based on nixpkgs orca-slicer)";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      orcaSrc = {
        version = "2.3.2-rc2";
        srcHash = "sha256-0W42k32h14qfZ2vaRBD5AHw0/mI/dLAzDfr2/t2mnZs=";
      };

      orca-slicer = pkgs.callPackage ./package.nix {
        orcaVersion = orcaSrc.version;
        orcaSrcHash = orcaSrc.srcHash;
      };
    in {
      packages.${system} = {
        default = orca-slicer;
        orca-slicer = orca-slicer;
      };

      overlays.default = final: prev: { orca-slicer = orca-slicer; };
    };
}

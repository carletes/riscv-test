{
  description = "RISC-V playground";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            dd_rescue
            guestfs-tools
            minicom
            qemu-utils

            # Keep this line if you use bash.
            bashInteractive
          ];

          shellHook = ''
          '';
        };
      });
}

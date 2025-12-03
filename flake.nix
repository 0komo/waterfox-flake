{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakelight.url = "github:nix-community/flakelight";
  };
  outputs =
    { self, flakelight, ... }@inputs:
    flakelight ./. (
      { lib, ... }:
      rec {
        systems = [ "x86_64-linux" ];
        inherit inputs;

        formatters = pkgs: {
          "*.nix" = lib.getExe pkgs.nixfmt;
        };

        packages.waterfox = { callPackage, ... }: callPackage ./package.nix { };
        packages.default = packages.waterfox;

        devShells.update-source = {
          packages =
            pkgs: with pkgs; [
              nushell
            ];
          shellHook = ''
            exec nu ./update-source.nu
          '';
        };
        devShells.check.shellHook = ''
          flags=()
          if nix --version | grep Lix >/dev/null; then
            flags+=(-L)
          fi

          exec nix flake check "''${flags[@]}"
        '';

        checks.full-version = pkgs: ''
          ${self.packages.${pkgs.system}.waterfox}/bin/waterfox --full-version
        '';
      }
    );
}

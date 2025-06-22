{
  description = "Example Go development environment for Zero to Nix";

  # Flake inputs
  inputs = {
    # Latest stable Nixpkgs
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    base-flake.url = "path:../../";
  };

  # Flake outputs
  outputs = { self, nixpkgs, base-flake }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        base = base-flake.legacyPackages.${system};
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      # Development environment output
      devShells = forAllSystems ({ pkgs, base }: {
        default = pkgs.mkShell {
          # The Nix packages provided in the environment
          packages = base.commonPackages ++ (with pkgs; [
            go # The Go CLI
            gotools # Go tools like goimports, godoc, and others
          ]);
        };
      });
    };
}

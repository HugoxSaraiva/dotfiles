{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew"; 

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { 
    self, 
    nix-darwin, 
    nixpkgs, 
    nix-homebrew, 
    home-manager,
    ...
    }@inputs:
  let
    inherit (nix-darwin.lib) darwinSystem;
    nixpkgsConfig = {
        config.allowUnfree = true;
    };
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs;
        [ 
            neofetch
            neovim
            tmux
            mkalias
            tldr
            fzf
            pam-reattach
            hugo
            prettierd
            ripgrep
            sqlite
            stow
            iterm2
            doctl
            nodejs_22
            qmk
            act
            cppcheck
            bear
            pkg-config
            check
            nix-direnv
        ];

      homebrew = {
          enable = true;
          brews = [
            "mas"
            "lld"
            "clang-format"
          ];
          casks = [
            "the-unarchiver"
            "shortcat"
          ];
          masApps = {
            "Magnet" = 441258766;
          };
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
      };

      fonts.packages = [
           pkgs.nerd-fonts.jetbrains-mono
         ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      # Hack to make pam-reattach work
      environment.etc."pam.d/sudo_local".text = ''
        # Written by nix-darwin
        auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
        auth       sufficient     pam_tid.so
      '';

      system.primaryUser = "hugo";
      system.defaults = {
          dock.autohide = false;
          loginwindow.GuestEnabled = false;
          NSGlobalDomain.KeyRepeat = 2;
      };

      # Enables sudo with touch ID
      security.pam.services.sudo_local.touchIdAuth = true;

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      nix.enable = false;
    };
  in
  {
    darwinConfigurations = {
        MacBook-Pro = darwinSystem {
            inherit inputs;
            system = "aarch64-darwin";
            modules = [ 
              ./configuration.nix
              configuration
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              {
                nix-homebrew = {
                  # Install Homebrew under the default prefix
                  enable = true;
                  # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                  enableRosetta = true;
                  # User owning the Homebrew prefix
                  user = "hugo";
                };
              }
            ];
          };
      };

    legacyPackages."aarch64-darwin" = let
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config = nixpkgsConfig;
        };
      in {
        pkgs = pkgs;

        # Shared package list
        commonPackages = with pkgs; [
          neofetch
          neovim
          tmux
          mkalias
          tldr
          fzf
          pam-reattach
          prettierd
          ripgrep
          iterm2
        ];
      };
  };
}

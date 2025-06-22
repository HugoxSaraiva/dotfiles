#! /bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$DIR")"

if ! command -v nix >/dev/null 2>&1; then
	echo "Nix not found. Installing Nix..."
	# Intall nix
	curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

# Load nix in current session
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

source "$DIR/test_nix_install.sh"

echo "Running stow"
nix run nixpkgs#stow -- -t "$HOME" -d "$DOTFILES_ROOT" .
echo "Stowed files to $HOME"

# Move nix darwin config files to expected folder since they can't be symlinks
cp -rf "$DOTFILES_ROOT/.config/nix-darwin/" "$HOME/.config/nix-darwin/"

# Activate nix darwin
sudo nix run nix-darwin -- switch --flake ~/.config/nix-darwin

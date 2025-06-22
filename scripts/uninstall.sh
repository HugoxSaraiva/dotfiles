echo "Uninstalling nix-darwin..."
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller

echo "Uninstalling nix"
/nix/nix-installer uninstall

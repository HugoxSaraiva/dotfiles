#! /bin/bash

echo "Testing Nix install"

# Cheking if determinate nix is installed
if ! nix --version 2>/dev/null | grep -q "Determinate Nix"; then
	echo "Determinate Nix is NOT installed"
	exit 1
fi

if nix run "nixpkgs#hello" >/dev/null 2>&1; then
	echo "Nix installed successfully"
else
	echo "Nix is not installed correctly"
	exit 1
fi

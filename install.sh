#!/bin/bash
set -e

echo "Building HarnessCLI..."
swift build -c release

echo "Installing to ~/.local/bin..."
mkdir -p ~/.local/bin
cp .build/release/HarnessCLI ~/.local/bin/harness

echo ""
echo "✓ HarnessCLI installed successfully!"
echo ""
echo "Add the following to your ~/.zshrc or ~/.bashrc if not already present:"
echo ""
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "Then run: source ~/.zshrc (or ~/.bashrc)"
echo ""
echo "You can now run 'harness .' from any directory"

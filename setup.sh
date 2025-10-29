#!/bin/bash
# Setup script for ml-bridge project structure

set -e

echo "==================================="
echo "ml-bridge Project Setup"
echo "==================================="
echo ""

# Check if we're in the right place
if [ ! -f "ImageBridge.cpp" ] || [ ! -f "ImageBridge.h" ]; then
    echo "ERROR: ImageBridge.cpp and ImageBridge.h not found in current directory"
    echo "Please run this script from the directory containing the plugin source files."
    exit 1
fi

echo "Setting up project structure..."
echo ""

# Create src directory
if [ -d "src" ]; then
    echo "⚠ src/ directory already exists"
    read -p "Move source files anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping src/ setup"
        exit 0
    fi
else
    mkdir -p src
    echo "✓ Created src/ directory"
fi

# Move source files
echo "Moving source files to src/..."
mv ImageBridge.cpp src/ 2>/dev/null && echo "  ✓ Moved ImageBridge.cpp" || echo "  ⚠ ImageBridge.cpp already in place"
mv ImageBridge.h src/ 2>/dev/null && echo "  ✓ Moved ImageBridge.h" || echo "  ⚠ ImageBridge.h already in place"

# Rename gitignore if present
if [ -f "gitignore.txt" ]; then
    mv gitignore.txt .gitignore
    echo "✓ Renamed gitignore.txt → .gitignore"
fi

# Create optional directories (commented out by default)
# mkdir -p python
# mkdir -p examples
# mkdir -p docs

echo ""
echo "==================================="
echo "Setup complete!"
echo "==================================="
echo ""
echo "Project structure:"
tree -L 2 2>/dev/null || ls -R

echo ""
echo "Next steps:"
echo "  1. make check   # Verify environment"
echo "  2. make build   # Compile plugin"
echo "  3. make install # Install to ~/.nuke"
echo ""

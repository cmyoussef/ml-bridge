#!/bin/bash
# Build ImageBridge - Ultra Simple Version

NUKE_VERSION="13.0v1"
NUKE_PATH="/usr/local/Nuke${NUKE_VERSION}"

echo "Building ImageBridge (Simple Version)"
echo "====================================="

# Check Nuke
if [ ! -d "$NUKE_PATH" ]; then
    echo "Error: Set NUKE_PATH in this script"
    exit 1
fi

# Build
mkdir -p build_simple
cd build_simple

cmake -DNUKE_INSTALL_PATH=$NUKE_PATH \
      -DCMAKE_BUILD_TYPE=Release \
      -f ../ImageBridge_CMakeLists.txt \
      ..

make -j$(nproc)

echo ""
echo "Done! Plugin: build_simple/ImageBridge.so"
echo ""
echo "To use:"
echo "1. Copy ImageBridge.so to ~/.nuke/"
echo "2. In Nuke: nuke.createNode('ImageBridge')"
echo "3. All networking handled in Python - see imagebridge_python.py"

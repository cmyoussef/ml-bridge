# ml-bridge

A simple Nuke plugin that bridges the viewer to external ML servers (like ComfyUI).

## What It Does

**Simple:** Reads from Nuke viewer → Encodes to base64 → Stores in knob

That's it! No server, no networking, no models. Just a bridge.

## Features

- ✅ Reads image from Nuke viewer
- ✅ Encodes to base64 and stores in `image_to_send` knob
- ✅ Decodes base64 from `image_received` knob
- ✅ Displays decoded image in viewer
- ✅ All networking handled by Python/Gizmo layer
- ✅ Works with any external server (ComfyUI, custom, etc.)

## Building at DNEG

### Setup Structure
```bash
# Quick setup
./setup.sh

# Or manual setup
mkdir src
mv ImageBridge.{cpp,h} src/
```

### Build Commands
```bash
# Check environment (verifies src/ structure)
make check

# Build plugin
make build

# Install to personal .nuke
make install

# Or install to shared location
make install-shared SHARED_PLUGIN_PATH=/path/to/shared
```

### Requirements

- Nuke 14.1v4 (or adjust in Makefile)
- Linux (tested on DNEG systems)
- CMake 3.10+
- C++11 compiler

## Quick Start

1. Build and install:
```bash
make build
make install
```

2. Add to `~/.nuke/init.py`:
```python
import nuke
nuke.pluginAddPath('~/.nuke/plugins/ml-bridge')
```

3. In Nuke:
```python
# Create node
bridge = nuke.createNode('ImageBridge')

# Execute to encode current image
nuke.execute(bridge, nuke.frame(), nuke.frame())

# Get encoded image
image_b64 = bridge['image_to_send'].value()

# Send to your ML server (your code here)
# ...

# Set result
bridge['image_received'].setValue(result_b64)
```

## Integration with ComfyUI

See `python/comfyui_bridge.py` for examples of connecting to ComfyUI.

## Architecture

```
Nuke Viewer → ImageBridge (C++) → Knob (base64)
                                      ↓
                              Python/Gizmo reads knob
                                      ↓
                              Sends to external server
                              (ComfyUI, custom, etc.)
                                      ↓
                              Returns base64 result
                                      ↓
Nuke Viewer ← ImageBridge (C++) ← Knob (base64)
```

The plugin is just the encoder/decoder. All intelligence lives in Python!

## Data Format

Images are encoded as:
```
width,height,channels|base64_encoded_float32_data
```

Example: `1920,1080,3|SGVsbG8gV29ybGQh...`

## Why This Design?

- **C++ does:** Fast image encoding/decoding
- **Python does:** ALL networking, logic, server communication
- **Gizmos do:** User interface, model-specific features

This separation makes it:
- Easy to modify (change Python, not C++)
- Flexible (works with any server)
- Maintainable (small C++ codebase)

## Project Structure

```
ml-bridge/
├── Makefile              # Build system
├── CMakeLists.txt       # CMake config
├── setup.sh             # Setup script (optional)
├── src/                 # C++ plugin source
│   ├── ImageBridge.cpp
│   └── ImageBridge.h
└── python/              # Python examples (optional)
    └── comfyui_bridge.py
```

## License

Apache 2.0

## Support

For DNEG-specific questions, contact your pipeline team.
For general issues, see docs/ folder.

## Notes

- This plugin does NOT include a server
- Server must be run separately (e.g., ComfyUI)
- All networking happens in Python, not C++
- Plugin is ~200 lines of C++ code total

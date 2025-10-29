// ImageBridge.cpp - Ultra Simple Image<->Base64 Bridge Implementation
#include "ImageBridge.h"
#include "DDImage/Knobs.h"
#include "DDImage/ImagePlane.h"
#include <vector>
#include <sstream>

// Base64 encoding table
static const char base64_chars[] = 
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// Simple base64 encode
std::string base64_encode(const unsigned char* bytes, size_t len) {
    std::string ret;
    int i = 0, j = 0;
    unsigned char char_array_3[3], char_array_4[4];
    
    while (len--) {
        char_array_3[i++] = *(bytes++);
        if (i == 3) {
            char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
            char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
            char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
            char_array_4[3] = char_array_3[2] & 0x3f;
            
            for(i = 0; i < 4; i++)
                ret += base64_chars[char_array_4[i]];
            i = 0;
        }
    }
    
    if (i) {
        for(j = i; j < 3; j++)
            char_array_3[j] = '\0';
            
        char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
        char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
        char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
        
        for (j = 0; j < i + 1; j++)
            ret += base64_chars[char_array_4[j]];
            
        while((i++ < 3))
            ret += '=';
    }
    
    return ret;
}

// Simple base64 decode
std::vector<unsigned char> base64_decode(const std::string& encoded) {
    std::vector<unsigned char> ret;
    int i = 0, j = 0, in_len = encoded.size();
    unsigned char char_array_4[4], char_array_3[3];
    
    while (in_len-- && (encoded[i] != '=')) {
        char c = encoded[i++];
        if (c >= 'A' && c <= 'Z') char_array_4[j++] = c - 'A';
        else if (c >= 'a' && c <= 'z') char_array_4[j++] = c - 'a' + 26;
        else if (c >= '0' && c <= '9') char_array_4[j++] = c - '0' + 52;
        else if (c == '+') char_array_4[j++] = 62;
        else if (c == '/') char_array_4[j++] = 63;
        else continue;
        
        if (j == 4) {
            char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
            char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
            char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];
            
            for (j = 0; j < 3; j++)
                ret.push_back(char_array_3[j]);
            j = 0;
        }
    }
    
    if (j) {
        for (int k = j; k < 4; k++)
            char_array_4[k] = 0;
            
        char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
        char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
        
        for (int k = 0; k < j - 1; k++)
            ret.push_back(char_array_3[k]);
    }
    
    return ret;
}

// Static constants
const char* const ImageBridge::kClassName = "ImageBridge";
const char* const ImageBridge::kHelpString = 
    "Simple image<->base64 bridge. Encodes current image to image_to_send knob.\n"
    "If image_received has base64 data, displays it. Otherwise passes input through.\n"
    "All networking handled by Python/Gizmo layer.";

// Factory function
static DD::Image::Iop* ImageBridgeCreate(Node* node) {
    return new ImageBridge(node);
}

// Plugin registration
const DD::Image::Iop::Description ImageBridge::description(
    ImageBridge::kClassName, 
    "ML/ImageBridge",
    ImageBridgeCreate
);

// Constructor
ImageBridge::ImageBridge(Node* node)
    : DD::Image::PlanarIop(node)
    , _image_to_send("")
    , _image_received("")
{
}

void ImageBridge::_validate(bool forReal) {
    // Just copy input info
    copy_info();
}

void ImageBridge::renderStripe(DD::Image::ImagePlane& imagePlane) {
    // First, fetch the input image
    input0().fetchPlane(imagePlane);
    
    // Encode current image to base64 and store in knob
    encodeCurrentImage(imagePlane);
    
    // If we have received image data, decode and use it
    if (!_image_received.empty() && _image_received != "") {
        decodeToImage(imagePlane);
    }
    // Otherwise, the input image passes through (already fetched above)
}

void ImageBridge::encodeCurrentImage(const DD::Image::ImagePlane& imagePlane) {
    const DD::Image::Box& bounds = imagePlane.bounds();
    int width = bounds.w();
    int height = bounds.h();
    int channels = imagePlane.channels().size();
    
    // Prepare header with dimensions
    std::stringstream header;
    header << width << "," << height << "," << channels << "|";
    std::string header_str = header.str();
    
    // Create buffer for image data
    size_t dataSize = width * height * channels * sizeof(float);
    std::vector<unsigned char> buffer(dataSize);
    float* floatBuffer = reinterpret_cast<float*>(buffer.data());
    
    // Copy image data
    int idx = 0;
    for (int c = 0; c < channels; ++c) {
        for (int y = bounds.y(); y < bounds.t(); ++y) {
            for (int x = bounds.x(); x < bounds.r(); ++x) {
                floatBuffer[idx++] = imagePlane.at(x, y, c);
            }
        }
    }
    
    // Encode to base64 with header
    _image_to_send = header_str + base64_encode(buffer.data(), dataSize);
    
    // Update the knob
    if (knob("image_to_send")) {
        knob("image_to_send")->set_text(_image_to_send.c_str());
    }
}

bool ImageBridge::decodeToImage(DD::Image::ImagePlane& imagePlane) {
    // Parse header (width,height,channels|base64data)
    size_t separator = _image_received.find('|');
    if (separator == std::string::npos) {
        return false;
    }
    
    std::string header = _image_received.substr(0, separator);
    std::string data = _image_received.substr(separator + 1);
    
    // Parse dimensions
    int width, height, channels;
    if (sscanf(header.c_str(), "%d,%d,%d", &width, &height, &channels) != 3) {
        return false;
    }
    
    // Decode base64
    std::vector<unsigned char> decoded = base64_decode(data);
    if (decoded.empty()) {
        return false;
    }
    
    float* floatData = reinterpret_cast<float*>(decoded.data());
    
    // Make image plane writable
    imagePlane.makeWritable();
    
    // Write decoded data to image plane
    const DD::Image::Box& bounds = imagePlane.bounds();
    int idx = 0;
    
    for (int c = 0; c < channels && c < imagePlane.channels().size(); ++c) {
        for (int y = bounds.y(); y < bounds.t() && y - bounds.y() < height; ++y) {
            for (int x = bounds.x(); x < bounds.r() && x - bounds.x() < width; ++x) {
                if (idx < decoded.size() / sizeof(float)) {
                    imagePlane.writableAt(x, y, c) = floatData[idx++];
                }
            }
        }
    }
    
    return true;
}

void ImageBridge::knobs(DD::Image::Knob_Callback f) {
    // Just two knobs - super simple!
    Multiline_String_knob(f, &_image_to_send, "image_to_send", "Image to Send");
    SetFlags(f, DD::Image::Knob::STARTLINE | DD::Image::Knob::READ_ONLY);
    Tooltip(f, "Current image encoded as base64 (automatically updated)");
    
    Multiline_String_knob(f, &_image_received, "image_received", "Image Received");
    SetFlags(f, DD::Image::Knob::STARTLINE);
    Tooltip(f, "Paste base64 image data here to display it");
}

int ImageBridge::knob_changed(DD::Image::Knob* k) {
    if (k->is("image_received")) {
        // Trigger re-render when received image changes
        invalidate();
        return 1;
    }
    return 0;
}

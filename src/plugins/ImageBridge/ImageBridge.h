// ImageBridge.h - Ultra Simple Image<->Base64 Bridge
#ifndef IMAGEBRIDGE_H
#define IMAGEBRIDGE_H

#include "DDImage/PlanarIop.h"
#include "DDImage/Knobs.h"
#include "DDImage/Row.h"
#include <string>

class ImageBridge : public DD::Image::PlanarIop {
public:
    static const char* const kClassName;
    static const char* const kHelpString;
    
    ImageBridge(Node* node);
    virtual ~ImageBridge() {}
    
    // DDImage::Iop overrides
    void _validate(bool);
    void renderStripe(DD::Image::ImagePlane& imagePlane);
    
    bool useStripes() const { return false; }
    bool renderFullPlanes() const { return true; }
    
    void knobs(DD::Image::Knob_Callback f);
    int knob_changed(DD::Image::Knob* k);
    
    const char* Class() const { return kClassName; }
    const char* node_help() const { return kHelpString; }
    
    static const DD::Image::Iop::Description description;
    
private:
    const char* _image_to_send;    // Changed from std::string
    const char* _image_received;   // Changed from std::string
    std::string _image_to_send_str;    // Internal storage
    std::string _image_received_str;   // Internal storage
    
    void encodeCurrentImage(const DD::Image::ImagePlane& imagePlane);
    bool decodeToImage(DD::Image::ImagePlane& imagePlane);
};

#endif // IMAGEBRIDGE_H

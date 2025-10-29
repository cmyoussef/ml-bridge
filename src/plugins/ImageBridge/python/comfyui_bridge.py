"""
ComfyUI Bridge Example
Connects ImageBridge plugin to ComfyUI server
"""

import nuke
import json
import urllib.request
import urllib.error


class ComfyUIBridge:
    """Bridge between Nuke ImageBridge node and ComfyUI server"""
    
    def __init__(self, host='127.0.0.1', port=8188):
        self.host = host
        self.port = port
        self.base_url = f'http://{host}:{port}'
        
    def check_server(self):
        """Check if ComfyUI server is running"""
        try:
            req = urllib.request.Request(f'{self.base_url}/system_stats')
            urllib.request.urlopen(req, timeout=2)
            return True
        except:
            return False
    
    def send_image(self, bridge_node, workflow=None):
        """
        Send image from ImageBridge node to ComfyUI
        
        Args:
            bridge_node: The ImageBridge Nuke node
            workflow: Optional ComfyUI workflow dict
            
        Returns:
            str: Result image as base64
        """
        # Get encoded image from bridge
        image_b64 = bridge_node['image_to_send'].value()
        
        if not image_b64:
            nuke.message('No image in image_to_send knob. Execute node first.')
            return None
        
        # Default simple workflow if none provided
        if workflow is None:
            workflow = self.get_default_workflow(image_b64)
        
        try:
            # Submit workflow to ComfyUI
            prompt_data = {
                'prompt': workflow,
                'client_id': 'nuke_bridge'
            }
            
            req = urllib.request.Request(
                f'{self.base_url}/prompt',
                data=json.dumps(prompt_data).encode('utf-8'),
                headers={'Content-Type': 'application/json'}
            )
            
            response = urllib.request.urlopen(req, timeout=30)
            result = json.loads(response.read().decode('utf-8'))
            prompt_id = result.get('prompt_id')
            
            if not prompt_id:
                nuke.message('Error: No prompt_id returned from ComfyUI')
                return None
            
            # Poll for completion
            return self.poll_for_result(prompt_id)
            
        except urllib.error.URLError as e:
            nuke.message(f'Connection error: {e}\n\nIs ComfyUI running on {self.host}:{self.port}?')
            return None
        except Exception as e:
            nuke.message(f'Error: {e}')
            return None
    
    def poll_for_result(self, prompt_id, timeout=60):
        """Poll ComfyUI for workflow result"""
        import time
        
        for i in range(timeout):
            time.sleep(1)
            
            try:
                # Check history
                req = urllib.request.Request(f'{self.base_url}/history/{prompt_id}')
                response = urllib.request.urlopen(req, timeout=5)
                history = json.loads(response.read().decode('utf-8'))
                
                if prompt_id in history:
                    # Get output - adjust node ID based on your workflow
                    outputs = history[prompt_id].get('outputs', {})
                    
                    # Look for base64 image in outputs
                    for node_id, node_output in outputs.items():
                        if 'images' in node_output:
                            for img in node_output['images']:
                                if 'image_base64' in img:
                                    return img['image_base64']
                    
                    nuke.message('Workflow complete but no base64 image found in outputs')
                    return None
                    
            except Exception as e:
                continue
        
        nuke.message(f'Timeout waiting for result from ComfyUI')
        return None
    
    def get_default_workflow(self, image_b64):
        """
        Get a simple default workflow
        Override this method for custom workflows
        """
        return {
            "1": {
                "inputs": {
                    "image": image_b64
                },
                "class_type": "LoadImageBase64"
            },
            "2": {
                "inputs": {
                    "images": ["1", 0]
                },
                "class_type": "SaveImageBase64"
            }
        }


def create_comfyui_bridge_node(host='127.0.0.1', port=8188):
    """
    Create a Nuke group that wraps ImageBridge with ComfyUI controls
    
    Usage:
        node = create_comfyui_bridge_node()
    """
    g = nuke.nodes.Group(name='ComfyUI_Bridge')
    g.begin()
    
    # Internal structure
    input_node = nuke.nodes.Input()
    
    # Create ImageBridge node
    bridge = nuke.createNode('ImageBridge')
    bridge.setInput(0, input_node)
    
    output = nuke.nodes.Output()
    output.setInput(0, bridge)
    
    g.end()
    
    # Add custom knobs
    tab = nuke.Tab_Knob('comfyui', 'ComfyUI')
    g.addKnob(tab)
    
    host_knob = nuke.String_Knob('comfy_host', 'Host')
    host_knob.setValue(host)
    g.addKnob(host_knob)
    
    port_knob = nuke.Int_Knob('comfy_port', 'Port')
    port_knob.setValue(port)
    g.addKnob(port_knob)
    
    # Process button
    process_btn = nuke.PyScript_Knob('process', 'Process with ComfyUI')
    process_btn.setCommand('''
# Get settings
host = nuke.thisNode()['comfy_host'].value()
port = int(nuke.thisNode()['comfy_port'].value())

# Get bridge node
bridge = nuke.thisNode().node('ImageBridge1')

# Import bridge class (make sure it's in PYTHONPATH)
try:
    from comfyui_bridge import ComfyUIBridge
except ImportError:
    nuke.message('Error: comfyui_bridge.py not in PYTHONPATH')
    raise

# Create bridge and process
comfy = ComfyUIBridge(host, port)

if not comfy.check_server():
    nuke.message(f'ComfyUI server not reachable at {host}:{port}')
else:
    result = comfy.send_image(bridge)
    if result:
        bridge['image_received'].setValue(result)
        nuke.message('Processing complete!')
''')
    g.addKnob(process_btn)
    
    return g


def simple_send_to_comfyui(bridge_node, host='127.0.0.1', port=8188):
    """
    Simple function to send current image to ComfyUI
    
    Usage:
        bridge = nuke.selectedNode()
        simple_send_to_comfyui(bridge)
    """
    comfy = ComfyUIBridge(host, port)
    
    if not comfy.check_server():
        nuke.message(f'ComfyUI server not running at {host}:{port}')
        return
    
    result = comfy.send_image(bridge_node)
    if result:
        bridge_node['image_received'].setValue(result)
        print('✓ Image processed and result set')
    else:
        print('✗ Processing failed')


# Example: Add menu items
def setup_menu():
    """Add ComfyUI bridge to Nuke menu"""
    try:
        menubar = nuke.menu('Nuke')
        ml_menu = menubar.addMenu('ML Bridge')
        
        ml_menu.addCommand(
            'ComfyUI Bridge', 
            lambda: create_comfyui_bridge_node(),
            'ctrl+shift+c'
        )
        
        ml_menu.addCommand(
            'Send Selected to ComfyUI',
            lambda: simple_send_to_comfyui(nuke.selectedNode()),
            'ctrl+shift+s'
        )
        
    except Exception as e:
        print(f'Menu setup error: {e}')


# Example usage in script
if __name__ == '__main__':
    # Create a ComfyUI bridge node
    node = create_comfyui_bridge_node()
    
    # Or use simple function
    # bridge = nuke.selectedNode()
    # simple_send_to_comfyui(bridge)

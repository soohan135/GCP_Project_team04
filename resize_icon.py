from PIL import Image
import os
import math

def check_file_exists(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}")
        return False
    return True

def resize_with_padding(input_path, output_path, content_ratio=0.7):
    """
    Adds padding to an image so that the original content occupies `content_ratio` (e.g. 70%) of the new canvas.
    """
    if not check_file_exists(input_path):
        return

    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Calculate new dimensions
        # New Dimension = Original Dimension / ratio
        # e.g. if width is 100 and ratio is 0.7, new width is 100/0.7 = 142.8
        
        new_width = int(math.ceil(width / content_ratio))
        new_height = int(math.ceil(height / content_ratio))
        
        # Create new transparent image (or white if preferred, but transparent for flexible foregrounds)
        # Using transparent for foreground layer is standard.
        new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
        
        # Calculate paste position to center the image
        paste_x = (new_width - width) // 2
        paste_y = (new_height - height) // 2
        
        new_img.paste(img, (paste_x, paste_y), img)
        
        new_img.save(output_path, "PNG")
        print(f"Successfully created 70% sized image at: {output_path}")
        print(f"Original Content: {width}x{height}")
        print(f"New Canvas: {new_width}x{new_height}")
        print(f"Padding added: X={paste_x}, Y={paste_y}")
            
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    # Input is the "tight" crop we made earlier
    input_file = r"e:\Users\sungj\Google Cloud bootcamp\project\project-0121\GCP_Project_team04\assets\images\app_logo_blue_void_right_tight.png"
    output_file = r"e:\Users\sungj\Google Cloud bootcamp\project\project-0121\GCP_Project_team04\assets\images\app_logo_blue_void_right_70.png"
    
    # Target: 70% size
    resize_with_padding(input_file, output_file, content_ratio=0.7)

from PIL import Image
import os

def check_file_exists(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}")
        return False
    return True

def add_padding(input_path, output_path, padding_factor=0.5):
    """
    Adds transparent padding to an image.
    padding_factor: The ratio of padding to add relative to the original size.
                    0.5 means the final image will be 150% of the original size,
                    effectively making the logo occupy 66% of the canvas.
    """
    if not check_file_exists(input_path):
        return

    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Calculate new dimensions
        # We want the original image to be centered and smaller.
        # If we want the logo to be X% of the splash screen, we increase the canvas.
        # Adding 50% padding to each side (doubling the canvas size) makes the logo 50% smaller visually.
        # Let's try adding substantial padding.
        # Android 12 splash circle is about 2/3 of screen width? 
        # Actually, let's just make the canvas significantly larger. 
        # If we double the canvas size (200%), the logo becomes 50% visually.
        
        # New size logic:
        # Padded version needs to be square ideally for best splash results, 
        # but let's keep aspect ratio and just add equal padding.
        
        padding_w = int(width * padding_factor)
        padding_h = int(height * padding_factor)
        
        new_width = width + (2 * padding_w)
        new_height = height + (2 * padding_h)
        
        # Create new transparent image
        new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
        
        # Paste original image in center
        paste_x = padding_w
        paste_y = padding_h
        new_img.paste(img, (paste_x, paste_y), img)
        
        new_img.save(output_path, "PNG")
        print(f"Successfully created padded image at: {output_path}")
        print(f"Original size: {width}x{height}")
        print(f"New size: {new_width}x{new_height}")
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    input_file = r"e:\Users\sungj\Google Cloud bootcamp\project\project-0121\GCP_Project_team04\assets\images\app_logo_blue_void_right.png"
    output_file = r"e:\Users\sungj\Google Cloud bootcamp\project\project-0121\GCP_Project_team04\assets\images\app_logo_blue_void_right_padded.png"
    
    # Using 0.6 padding factor (1.2 total padding) -> Logo will be ~45% of total width
    add_padding(input_file, output_file, padding_factor=0.6)

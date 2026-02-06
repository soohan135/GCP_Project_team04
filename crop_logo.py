from PIL import Image, ImageChops
import os

def check_file_exists(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}")
        return False
    return True

def crop_content(input_path, output_path):
    """
    Crops the image to the bounding box of non-white and non-transparent pixels.
    """
    if not check_file_exists(input_path):
        return

    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Create a background to diff against.
        # We assume background is either transparent or white.
        bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
        diff = ImageChops.difference(img, bg)
        bbox = diff.getbbox()
        
        # If diff is empty, maybe it was transparent?
        # Let's also check against transparent background
        if not bbox:
            bg_trans = Image.new("RGBA", img.size, (0, 0, 0, 0))
            diff_trans = ImageChops.difference(img, bg_trans)
            bbox = diff_trans.getbbox()

        if bbox:
            # We found content!
            # Let's add a tiny margin (e.g. 5%) so it's not literally touching the edge
            # which might look bad if Android applies a mask.
            # actually user wants "full" (꽉 차도록), so maybe 0 margin or very small.
            
            cropped_img = img.crop(bbox)
            
            # Optional: Add small padding (e.g. 10px) just to be safe
            # But for now, let's just save the tight crop because adaptive icons add their own padding.
            cropped_img.save(output_path, "PNG")
            
            new_width, new_height = cropped_img.size
            print(f"Successfully created tight crop at: {output_path}")
            print(f"Original: {width}x{height}")
            print(f"New: {new_width}x{new_height}")
        else:
            print("Error: Could not determine bounding box (image might be empty or full white/transparent).")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    input_file = r"e:\Users\sungj\Google Cloud bootcamp\project\project-0121\GCP_Project_team04\assets\images\app_logo_blue_void_right.png"
    output_file = r"e:\Users\sungj\Google Cloud bootcamp\project\project-0121\GCP_Project_team04\assets\images\app_logo_blue_void_right_tight.png"
    
    crop_content(input_file, output_file)

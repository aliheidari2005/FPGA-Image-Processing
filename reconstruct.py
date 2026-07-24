import numpy as np
from PIL import Image
import os

# Configuration
INPUT_FILE = "output_image.txt"
OUTPUT_FILE = "reconstructed_output.png"
IMG_WIDTH = 128
IMG_HEIGHT = 128

def reconstruct_image():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    # Read the hex strings and convert to integers
    with open(INPUT_FILE, "r") as f:
        pixel_data = [int(line.strip(), 16) for line in f if line.strip()]

    # Verify we got exactly 16384 pixels
    if len(pixel_data) != (IMG_WIDTH * IMG_HEIGHT):
        print(f"Warning: Expected {IMG_WIDTH * IMG_HEIGHT} pixels, but got {len(pixel_data)}.")

    # Convert to a numpy array of unsigned 8-bit integers
    img_array = np.array(pixel_data, dtype=np.uint8)
    
    # Reshape the 1D array into a 128x128 2D grid
    img_array = img_array.reshape((IMG_HEIGHT, IMG_WIDTH))

    # Convert the array to an image and save
    img = Image.fromarray(img_array, mode="L") # "L" mode is for 8-bit grayscale
    img.save(OUTPUT_FILE)
    print(f"Success! Image saved as {OUTPUT_FILE}")

if __name__ == "__main__":
    reconstruct_image()
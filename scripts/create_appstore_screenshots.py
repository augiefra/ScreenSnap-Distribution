#!/usr/bin/env python3
"""
Create App Store formatted screenshots with blurred background
Usage: python3 create_appstore_screenshots.py <input_image> [output_size]

Sizes: 1280x800, 1440x900, 2560x1600, 2880x1800
Default: 1440x900
"""

import sys
from PIL import Image, ImageFilter
import os


def create_appstore_screenshot(input_path, output_size=(1440, 900), blur_radius=40):
    """
    Creates an App Store formatted screenshot with blurred background

    Args:
        input_path: Path to input image
        output_size: Tuple (width, height) for output
        blur_radius: Gaussian blur radius for background
    """
    # Open original image
    original = Image.open(input_path)

    # Create blurred background
    # Resize original to fill the target size (maintaining aspect ratio to cover)
    bg_width, bg_height = output_size
    orig_width, orig_height = original.size

    # Calculate scale to fill the background
    scale_w = bg_width / orig_width
    scale_h = bg_height / orig_height
    scale = max(scale_w, scale_h)

    # Resize and crop to fill
    new_width = int(orig_width * scale)
    new_height = int(orig_height * scale)
    background = original.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # Center crop to exact size
    left = (new_width - bg_width) // 2
    top = (new_height - bg_height) // 2
    background = background.crop((left, top, left + bg_width, top + bg_height))

    # Apply Gaussian blur
    background = background.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    # Calculate position to center original image
    # Scale original down if it's too large (leaving 5% margin)
    max_width = int(bg_width * 0.9)
    max_height = int(bg_height * 0.9)

    if orig_width > max_width or orig_height > max_height:
        # Scale down maintaining aspect ratio
        scale = min(max_width / orig_width, max_height / orig_height)
        new_orig_width = int(orig_width * scale)
        new_orig_height = int(orig_height * scale)
        centered_img = original.resize((new_orig_width, new_orig_height), Image.Resampling.LANCZOS)
    else:
        centered_img = original

    # Calculate centering position
    paste_x = (bg_width - centered_img.width) // 2
    paste_y = (bg_height - centered_img.height) // 2

    # Paste original on top of blurred background
    background.paste(centered_img, (paste_x, paste_y))

    # Generate output filename
    input_name = os.path.splitext(os.path.basename(input_path))[0]
    output_name = f"{input_name}_appstore_{bg_width}x{bg_height}.png"
    output_dir = os.path.dirname(input_path) or "."
    output_path = os.path.join(output_dir, output_name)

    # Save
    background.save(output_path, "PNG", quality=95)
    print(f"✅ Created: {output_path}")
    return output_path


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 create_appstore_screenshots.py <input_image> [size]")
        print("\nAvailable sizes:")
        print("  - 1280x800")
        print("  - 1440x900 (default)")
        print("  - 2560x1600")
        print("  - 2880x1800")
        print("\nExample:")
        print("  python3 create_appstore_screenshots.py screenshot.png 1440x900")
        sys.exit(1)

    input_path = sys.argv[1]

    # Parse size argument
    size_map = {
        "1280x800": (1280, 800),
        "1440x900": (1440, 900),
        "2560x1600": (2560, 1600),
        "2880x1800": (2880, 1800),
    }

    if len(sys.argv) >= 3:
        size_key = sys.argv[2]
        if size_key not in size_map:
            print(f"❌ Invalid size: {size_key}")
            print(f"Available: {', '.join(size_map.keys())}")
            sys.exit(1)
        output_size = size_map[size_key]
    else:
        output_size = (1440, 900)  # Default

    if not os.path.exists(input_path):
        print(f"❌ File not found: {input_path}")
        sys.exit(1)

    create_appstore_screenshot(input_path, output_size)
    print(f"\n📐 Output size: {output_size[0]}x{output_size[1]}")


if __name__ == "__main__":
    main()

from pathlib import Path
import argparse

from PIL import Image, ImageDraw


def generate_checkerboard(output_path, size=1080, squares=8):
    """Generate a black-white checkerboard image for calibration capture."""
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    img = Image.new("RGB", (size, size), "black")
    draw = ImageDraw.Draw(img)
    square_size = size // squares

    for row in range(squares):
        for col in range(squares):
            if (row + col) % 2 == 1:
                top = row * square_size
                left = col * square_size
                bottom = top + square_size
                right = left + square_size
                draw.rectangle([left, top, right, bottom], fill="white")

    img.save(output_path)
    return output_path


def parse_args():
    parser = argparse.ArgumentParser(description="Generate a calibration checkerboard image.")
    parser.add_argument("--size", type=int, default=1080, help="Output image width and height in pixels.")
    parser.add_argument("--squares", type=int, default=8, help="Number of squares per row and column.")
    parser.add_argument(
        "--output",
        default="images/checkerboard.png",
        help="Output image path relative to the project root.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    output = generate_checkerboard(args.output, args.size, args.squares)
    print(f"Saved checkerboard to {output}")
